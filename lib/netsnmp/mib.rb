# frozen_string_literal: true

require_relative "mib/parser"

module NETSNMP
  module MIB
    # @rbs!
    #   type import = {ids: Array[{name: string}] | {name: string}, name: string}

    OIDREGEX = /^[\d.]*$/.freeze #: Regexp

    module_function

    MIBDIRS = ENV.fetch("MIBDIRS", File.join("/usr", "share", "snmp", "mibs"))
                 .split(":")
                 .flat_map { |dir| [dir, *Dir.glob(File.join(dir, "**", "*")).select(&File.method(:directory?))] }.uniq #: Array[String]
    PARSER = Parser.new #: Parser

    # @rbs self.@parser_mutex: Thread::Mutex
    @parser_mutex = Mutex.new

    # @rbs self.@modules_loaded: Array[String]
    @modules_loaded = []

    # @rbs self.@object_identifiers: Hash[String, String]
    @object_identifiers = {}

    # Translates na identifier, such as "sysDescr", into an OID
    #: (oid) -> String?
    def oid(identifier)
      prefix, *suffix = case identifier
                        when Array
                          identifier.map(&:to_s)
                        else
                          identifier.split(".", 2).map(&:to_s)
                        end

      return unless prefix

      # early exit if it's an OID already
      unless integer?(prefix)
        load_defaults
        # load module if need be
        idx = prefix.index("::")
        if idx
          mod = prefix[0..(idx - 1)]
          type = prefix[(idx + 2)..-1]
          return if mod && !module_loaded?(mod) && !load(mod)
        else
          type = prefix
        end

        return if type.nil? || type.empty?

        prefix = @object_identifiers[type] ||
                 raise(Error, "can't convert #{type} to OID")

      end

      [prefix, *suffix].join(".")
    end

    #: (String) -> oid?
    def identifier(oid)
      @object_identifiers.select do |_, ids_oid|
        oid.start_with?(ids_oid)
      end.min_by(&:size)
    end

    #
    # Loads a MIB. Can be called multiple times, as it'll load it once.
    #
    # Accepts the MIB name in several ways:
    #
    #     MIB.load("SNMPv2-MIB")
    #     MIB.load("SNMPv2-MIB.txt")
    #     MIB.load("/path/to/SNMPv2-MIB.txt")
    #
    #: (String mod) -> bool
    def load(mod) # rubocop:disable Naming/PredicateMethod
      unless File.file?(mod)
        moddir = nil #: String?
        MIBDIRS.each do |mibdir|
          if File.exist?(File.join(mibdir, mod))
            moddir = File.join(mibdir, mod)
            break
          elsif File.extname(mod).empty? && File.exist?(File.join(mibdir, "#{mod}.txt"))
            moddir = File.join(mibdir, "#{mod}.txt")
            break
          end
        end
        return false unless moddir

        mod = moddir
      end
      return true if @modules_loaded.include?(mod)

      do_load(mod)
      @modules_loaded << mod
      true
    end

    #: (String mod) -> bool
    def module_loaded?(mod)
      if File.file?(mod)
        @modules_loaded.include?(mod)
      else
        @modules_loaded.map { |path| File.basename(path, ".*") }.include?(mod)
      end
    end

    TYPES = ["OBJECT IDENTIFIER", "OBJECT-TYPE", "MODULE-IDENTITY", "OBJECT-IDENTITY"].freeze #: Array[String]

    STATIC_MIB_TO_OID = {
      "iso" => "1"
    }.freeze #: Hash[String, String]

    #
    # Loads the MIB all the time, where +mod+ is the absolute path to the MIB.
    #
    #: (String mod) -> void
    def do_load(mod)
      data = @parser_mutex.synchronize { PARSER.parse(File.read(mod)) }

      imports = load_imports(data[:imports])

      declarations = Hash[
        data[:declarations].reject { |dec| !dec.key?(:name) || !TYPES.include?(dec[:type]) }
                           .map { |dec| [String(dec[:name]), String(dec[:value]).split(/ +/)] }
      ]

      declarations.each do |nme, value|
        store_oid_in_identifiers(nme, value, imports: imports, declarations: declarations)
      end
    end

    #: (String name, Array[String] value, imports: Hash[String, Array[String]]?, declarations: Hash[String, Array[String]]) -> void
    def store_oid_in_identifiers(nme, value, imports:, declarations:)
      oid = value.flat_map do |cp|
        if integer?(cp)
          cp
        elsif @object_identifiers.key?(cp)
          @object_identifiers[cp]
        elsif declarations.key?(cp)
          store_oid_in_identifiers(cp, declarations[cp], imports: imports, declarations: declarations)
          @object_identifiers[cp]
        else
          STATIC_MIB_TO_OID[cp] || begin
            imported_mod, = if imports
                              imports.find do |_, identifiers|
                                identifiers.include?(cp)
                              end
                            end

            raise Error, "didn't find a module to import \"#{cp}\" from" unless imported_mod

            load(imported_mod)

            @object_identifiers[cp]
          end
        end
      end.join(".")

      @object_identifiers[nme] = oid
    end

    #
    # Reformats the import lists into an hash indexed by module name, to a list of
    # imported names
    #
    #: (Array[import] | import | nil) -> Hash[String, Array[String]]?
    def load_imports(imports)
      return unless imports

      imports = Array(imports) #: Array[import]
      imports.to_h do |import|
        [String(import[:name]), case import[:ids]
                                when Hash
                                  [String(import[:ids][:name])]
                                else
                                  import[:ids].map { |id| String(id[:name]) }
                                end]
      end
    end

    #: (String) -> bool
    def integer?(val)
      val.each_byte do |byte|
        return false unless byte.between?(48, 57)
      end
      true
    end

    #: -> void
    def load_defaults
      # loading the defaults MIBS
      load("SNMPv2-MIB")
      load("IF-MIB")
    end

    #: -> void
    def freeze
      @modules_loaded.each(&:freeze).freeze
      @object_identifiers.each_key(&:freeze).each_value(&:freeze).freeze
      super
    end
  end
end
