require 'benchmark/driver/configuration'

class Benchmark::Driver::RubyDslParser
  # @param [Symbol,nil] runner - If this is nil, this is automatically decided by Benchmark::Driver#runner_type_for
  # @param [Symbol] output
  def initialize(runner: nil, output: :ips)
    @prelude = nil
    @jobs = []
    @runner = runner
    @execs = nil
    @bundler = false
    @output = output
    @compare = false
  end

  # API to fetch configuration parsed from DSL
  # @return [Benchmark::Driver::Configuration]
  def configuration
    @jobs.each do |job|
      job.prelude = @prelude
    end
    Benchmark::Driver::Configuration.new(@jobs).tap do |c|
      c.runner_options = Benchmark::Driver::Configuration::RunnerOptions.new(@runner, @execs, nil, @bundler)
      c.output_options = Benchmark::Driver::Configuration::OutputOptions.new(@output, @compare)
    end
  end

  # @param [String] prelude_script - Script required for benchmark whose execution time is not measured.
  def prelude(prelude_script)
    unless prelude_script.is_a?(String)
      raise ArgumentError.new("prelude must be String but got #{prelude_script.inspect}")
    end
    unless @prelude.nil?
      raise ArgumentError.new("prelude is already set:\n#{@prelude}")
    end

    @prelude = prelude_script
  end

  # @param [Array<String>] specs
  def rbenv(*specs)
    @execs ||= []
    specs.each do |spec|
      @execs << Benchmark::Driver::Configuration::Executable.parse_rbenv(spec)
    end
  end

  def bundler
    @bundler = true
  end

  # @param [String,nil] name   - Name shown on result output. This must be provided if block is given.
  # @param [String,nil] script - Benchmarked script in String. Only either of script or block must be provided.
  # @param [Proc,nil]   block  - Benchmarked Proc object.
  def report(name = nil, script = nil, &block)
    if !script.nil? && block_given?
      raise ArgumentError.new('script and block cannot be specified at the same time')
    elsif name.nil? && block_given?
      raise ArgumentError.new('name must be specified if block is given')
    elsif !name.nil? && !name.is_a?(String)
      raise ArgumentError.new("name must be String but got #{name.inspect}")
    elsif !script.nil? && !script.is_a?(String)
      raise ArgumentError.new("script must be String but got #{script.inspect}")
    end

    @jobs << Benchmark::Driver::Configuration::Job.new(name, script || block || name)
  end

  def compare!
    @compare = true
  end
end
