# Config
SERVER = "http://localhost:4567"
MAX_INSTANCES = 2
TESTBOT_VERSION = 2

require 'rubygems'
require 'httparty'
require 'macaddr'

class Job
  def initialize(id, root, specs)
    @id, @root, @specs = id, root, specs
  end
  
  def run(instance)
    puts "Running job #{@id} in instance #{instance}... "
    system "rsync -az --delete -e ssh #{@root}/ instance#{instance}"
    test_env_number = (instance == 0) ? '' : instance + 1
    result = `export RAILS_ENV=test; export TEST_ENV_NUMBER=#{test_env_number}; export RSPEC_COLOR=true; cd instance#{instance}; rake testbot:prepare; script/spec -O spec/spec.opts #{@specs}`
    Server.put("/jobs/#{@id}", :body => { :result => result })
    puts "Job #{@id} finished."
  end
end

class Server
  include HTTParty
  base_uri SERVER
end

class Runner
  
  def initialize
    @instances = []
  end
  
  def run!
    loop do
      sleep 1
      next_job = Server.get("/jobs/next", :query => query_params) rescue nil
      next if next_job == nil
      @instances << [ Thread.new { Job.new(*next_job.split(',')).run(free_instance_number) },
                      free_instance_number ]
      loop do
        clear_completed_instances
        break unless max_instances_running?
      end
    end
  end
  
  private
  
  def query_params
    { :version => TESTBOT_VERSION, :mac => Mac.addr, :hostname => (@hostname ||= `hostname`.chomp),
      :idle_instances => (MAX_INSTANCES - @instances.size) }
  end
  
  def max_instances_running?
    @instances.size == MAX_INSTANCES
  end

  def clear_completed_instances
    @instances.each_with_index do |data, index|
      @instances.delete_at(index) if data.first.join(0.25)
    end
  end

  def free_instance_number
    0.upto(MAX_INSTANCES - 1) do |number|
      return number unless @instances.find { |instance, n| n == number }
    end
  end
   
end

runner = Runner.new
runner.run!
