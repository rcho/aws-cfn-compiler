module Aws
  module Cfn
    module Compiler
      module Load

        # --------------------------------------------------------------------------------
        def get_file_set(want, path, exts=[])
          raise "Bad call to #{self.class.name}.get_file_set: want == nil" unless want
          @logger.debug "Look for #{want.ai} in #{[path]} with #{exts} extensions"
          if exts.nil?
            exts = @config[:precedence]
          end
          file_regex=%r/^(\S+)\.(#{exts.join('|')})$/
          if exts.empty?
            file_regex=%r/^(\S+)()$/
            exts=['']
          end
          regex = "^(#{want.join('|')})$"
          set = {}
          abs = File.expand_path(path)
          abs = path unless @config[:expandedpaths]
          raise "Oops! Does '#{path}' directory exist?" unless File.directory?(abs)
          #abs = File.realpath(abs)
          begin
            Dir.glob("#{abs}/*").each{ |f|
              match = File.basename(f).match(file_regex)
              if match
                name = match[1]
                ext  = match[2]
                set[ext] = {} unless set[ext]
                @logger.trace "#{name} =~ #{regex}"
                set[ext][name] = f if name.match(regex)
              end
            }
          rescue RegexpError => e
            raise "The regular expression attempting to match resources in '#{path}' is incorrect! #{e.message}"
          end
          @logger.debug "getPathSet set=#{set.ai}"
          res = {}
          # Iterate extension sets in increasing precedence order ...
          # Survivor will be the most desireable version of the item
          # i.e. the .rb environment, role, data bag, etc. will be preferred over the .json version
          exts.each{ |e|
            h = set[e]
            if h
              h.each{ |n,f|
                @logger.info "Ignoring #{File.basename(res[n])}" if res[n]
                res[n] = f
              }
            else
              @logger.debug "'#{e}' set is empty! (No #{path}/*.#{e} files found using precedence #{exts})"
            end
          }
          res
        end

        def vet_path(dir,base=nil,rel=false)
          if rel
            base = File.realpath(File.expand_path(File.join(@config[:directory], base)))
          else
            base = @config[:directory] unless base
          end
          path = nil
          [dir, dir.downcase].each do |d|
            path = File.join(base, dir)
            if File.directory?(path)
              break
            end
          end
          unless File.directory?(path)
            @logger.error "  !! error: Cannot load bricks from #{path} (started with #{File.join(base, dir)}')"
            abort!
          end
          path
        end


      end
    end
  end
end