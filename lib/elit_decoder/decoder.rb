# frozen_string_literal: true

require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'logger'
require 'rest-client'
require 'retriable'
require 'elit_decoder/error'
require 'active_support/core_ext/hash/except'

module ElitDecoder
  module Decoder
    module_function

    def server_url(language, action)
      @server_url ||= if language == 'python'
                        ElitDecoder.python_server_url + action
                      elsif language == 'java'
                        ElitDecoder.java_server_url + action
      end
    end

    def schema
      @schema ||= ElitDecoder.schema
    end
    # params = {
    #   input: "hello world",
    #   task: "pos",
    #   framework: "spacy",
    #   arguments: {
    #
    #   },
    #   dependencies: [
    #     {
    #       task: "tok",
    #       framework: "elit",
    #       arguments: "",
    #     }
    #   ]
    # }

    def params_parser(params)
      dependencies = params[:dependencies] || []
      pipeline = []
      main_job = {}
      if schema.key?(params[:task])
        # main task
        main_job[:task] = params[:task]
        main_job[:arguments] = params[:arguments]
        main_job[:framework] = if params[:framework]
                            params[:framework]
                          elsif schema[main_job[:task]].key?(:elit)
                            'elit'
                          else
                            schema[main_job[:task]].keys.first
        end
        if schema[main_job[:task]].key?(main_job[:framework])
          main_job[:language] = schema[main_job[:task]][main_job[:framework]]['language']
        else
          raise MissFrameworkError, "framework: #{params[:framework]} does not exist"
        end
        pipeline.push(main_job)
      else
        raise MissTaskError, "task: #{params[:task]} does not exist"
      end
      s = schema[main_job[:task]][main_job[:framework]]
      until s['dependencies'].empty?
        job = {}
        dep_task = s['dependencies']
        job[:task] = dep_task
        job[:framework] = schema[dep_task].key?(:elit) ? 'elit' : (main_job[:task] == 'all' ? main_job[:framework] : schema[dep_task].keys.first) 
        unless schema[dep_task].key?(job[:framework])
          raise MissFrameworkError, "framework: #{params[:framework]} does not exist"
        end
        job[:arguments] = schema[dep_task][job[:framework]]['arguments']
        job[:language] = schema[dep_task][job[:framework]]['language']
        dependencies.each do |dep|
          next unless dep_task == dep[:task]
          job[:framework] = dep[:framework]
          job[:arguments] = dep[:arguments]
          job[:language] = schema[dep_task][job[:framework]]['language']
        end
        pipeline.push(job)
        s = schema[job[:task]][job[:framework]]
      end
      pipeline
    end

    def job_scheduler(pipeline)
      jobs = []
      sub = {}
      current_lang = nil
      until pipeline.empty?
        job = pipeline.pop
        if current_lang == job[:language]
          sub[:pipeline].push(job)
        else
          jobs.push(sub) unless current_lang.nil?
          sub = {}
          current_lang = job[:language]
          sub[:language] = current_lang
          sub[:pipeline] = [job]
        end
      end
      jobs.push(sub)
      jobs
    end

    def decode(params)
      # keep input
      input = params[:input]
      is_file = params[:is_file]
      pipeline = params_parser(params.except(:input))
      jobs = job_scheduler(pipeline)
      output = ''
      jobs.each do |job|
        data = {
          input: input,
          is_file: is_file,
          pipeline: job[:pipeline]
        }
        output = Retriable.retriable(tries: 10) do
          RestClient.post server_url(job[:language], 'pipeline'),
                          data.to_json, content_type: :json, accept: :json
        end
        input = JSON.parse(output.body)
      end
      JSON.parse(output.body)
    end
  end
end
