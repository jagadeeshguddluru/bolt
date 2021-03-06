# frozen_string_literal: true

require 'bolt/error'
require 'bolt/config/transport/base'

module Bolt
  class Config
    module Transport
      class SSH < Base
        OPTIONS = {
          "connect-timeout"    => { type: Integer,
                                    desc: "How long to wait when establishing connections." },
          "disconnect-timeout" => { type: Integer,
                                    desc: "How long to wait before force-closing a connection." },
          "host"               => { type: String,
                                    desc: "Host name." },
          "host-key-check"     => { type: TrueClass,
                                    desc: "Whether to perform host key validation when connecting." },
          "interpreters"       => { type: Hash,
                                    desc: "A map of an extension name to the absolute path of an executable, "\
                                          "enabling you to override the shebang defined in a task executable. The "\
                                          "extension can optionally be specified with the `.` character (`.py` and "\
                                          "`py` both map to a task executable `task.py`) and the extension is case "\
                                          "sensitive. When a target's name is `localhost`, Ruby tasks run with the "\
                                          "Bolt Ruby interpreter by default." },
          "load-config"        => { type: TrueClass,
                                    desc: "Whether to load system SSH configuration." },
          "password"           => { type: String,
                                    desc: "Login password." },
          "port"               => { type: Integer,
                                    desc: "Connection port." },
          "private-key"        => { desc: "Either the path to the private key file to use for authentication, or a "\
                                          "hash with the key `key-data` and the contents of the private key." },
          "proxyjump"          => { type: String,
                                    desc: "A jump host to proxy connections through, and an optional user to "\
                                          "connect with." },
          "run-as"             => { type: String,
                                    desc: "A different user to run commands as after login." },
          "run-as-command"     => { type: Array,
                                    desc: "The command to elevate permissions. Bolt appends the user and command "\
                                          "strings to the configured `run-as-command` before running it on the "\
                                          "target. This command must not require an interactive password prompt, "\
                                          "and the `sudo-password` option is ignored when `run-as-command` is "\
                                          "specified. The `run-as-command` must be specified as an array." },
          "script-dir"         => { type: String,
                                    desc: "The subdirectory of the tmpdir to use in place of a randomized "\
                                          "subdirectory for uploading and executing temporary files on the "\
                                          "target. It's expected that this directory already exists as a subdir "\
                                          "of tmpdir, which is either configured or defaults to `/tmp`." },
          "sudo-executable"    => { type: String,
                                    desc: "The executable to use when escalating to the configured `run-as` "\
                                          "user. This is useful when you want to escalate using the configured "\
                                          "`sudo-password`, since `run-as-command` does not use `sudo-password` "\
                                          "or support prompting. The command executed on the target is "\
                                          "`<sudo-executable> -S -u <user> -p custom_bolt_prompt <command>`. "\
                                          "**This option is experimental.**" },
          "sudo-password"      => { type: String,
                                    desc: "Password to use when changing users via `run-as`." },
          "tmpdir"             => { type: String,
                                    desc: "The directory to upload and execute temporary files on the target." },
          "tty"                => { type: TrueClass,
                                    desc: "Request a pseudo tty for the session. This option is generally "\
                                          "only used in conjunction with the `run-as` option when the sudoers "\
                                          "policy requires a `tty`." },
          "user"               => { type: String,
                                    desc: "Login user." }
        }.freeze

        DEFAULTS = {
          "connect-timeout"    => 10,
          "tty"                => false,
          "load-config"        => true,
          "disconnect-timeout" => 5
        }.freeze

        private def validate
          super

          if (key_opt = @config['private-key'])
            unless key_opt.instance_of?(String) || (key_opt.instance_of?(Hash) && key_opt.include?('key-data'))
              raise Bolt::ValidationError,
                    "private-key option must be a path to a private key file or a Hash containing the 'key-data', "\
                    "received #{key_opt.class} #{key_opt}"
            end

            if key_opt.instance_of?(String)
              @config['private-key'] = File.expand_path(key_opt, @boltdir)
            end
          end

          if @config['interpreters']
            @config['interpreters'] = normalize_interpreters(@config['interpreters'])
          end

          if (run_as_cmd = @config['run-as-command'])
            unless run_as_cmd.all? { |n| n.is_a?(String) }
              raise Bolt::ValidationError,
                    "run-as-command must be an Array of Strings, received #{run_as_cmd.class} #{run_as_cmd.inspect}"
            end
          end
        end
      end
    end
  end
end
