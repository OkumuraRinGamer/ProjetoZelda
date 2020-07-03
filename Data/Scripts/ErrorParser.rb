#==============================================================================
# ** ErrorParser
#------------------------------------------------------------------------------
#  This improves the error messages in debug mode. You can change the message
#  templates to your likings (for both debug and normal mode).
#  Supports errors in external files.
#==============================================================================

=begin script
	Name "ErrorParser"
	Insert_Before "Game_Temp"
=end

module ErrorParser
  # This is the template for the message shown in debug mode.
  # CLASS, FILETYPE, FILENAME, LINE, METHOD, MESSAGE and TRACE get replaced
  # by the relevant information about the error.
  TEMPLATE_DEBUG = <<STRING
CLASS occurred!
FILETYPE: FILENAME
Line: LINE
SOURCETYPE: SOURCE
Message: MESSAGE

Trace:
TRACE
STRING
  # This is the template for the message shown in normal mode.
  # You can use all of the variables from above.
  TEMPLATE_DEFAULT = "FILETYPE 'FILENAME' line LINE: CLASS occurred!\n\nMESSAGE"
  # This will be used as the template for an entry in the stack trace.
  # CLASS, MESSAGE, and TRACE cannot be used here.
  TEMPLATE_TRACE_ENTRY = "FILETYPE 'FILENAME' line LINE (SOURCETYPE SOURCE)"
  # This is the template for line numbers in events.
  TEMPLATE_EVENT_LINE = "COMMAND/LINE"
  # This is the FILETYPE for scripts in Scripts.rxdata
  FILETYPE_SCRIPT = 'Script'
  # This is the FILETYPE for scripts called from an event
  FILETYPE_EVENT = 'Event'
  # This is the FILETYPE for otherwise evaled scripts
  FILETYPE_UNKNOWN = 'Unknown source'
  # This is the FILETYPE for external Ruby scripts (if used).
  FILETYPE_FILE = 'File'
  
  # This is the SOURCETYPE for methods in a script or file
  SOURCETYPE_METHOD = 'Method'
  # This is the SOURCETYPE for script calls from events
  SOURCETYPE_MAP = 'Map'
  # This is the SOURCETYPE for code from main block or class body
  SOURCETYPE_MAIN = 'In'
  # This will be used whereever we fail to parse the error correctly.
  UNKNOWN = '<unknown>'

  # Modifies the Main script to pass any errors to ErrorParser
  MAIN_CODE = <<CODE
rescue
  ErrorParser.exit_with_message
  #retry
CODE
  $RGSS_SCRIPTS[-1][3].insert(
    $RGSS_SCRIPTS[-1][3].rindex('rescue'), MAIN_CODE
  )

  # Modifies the Interpreter script to output extra error information or
  # errors in Call Script commands
  INTERPRETER_CODE = <<CODE
begin
  eval script
rescue ScriptError, StandardError
  $!.message.insert(5,
    ":\#{@map_id}:\#{@event_id}:\#{@index + 1}:\#{$!.message[7, 1]}"
  )
  raise
end
CODE
  $RGSS_SCRIPTS.each do |a|
    if a[1] == "Interpreter 7"
      a[3].sub! 'eval(script)', INTERPRETER_CODE
      break
    end
  end

  # Perform new error handling
  def self.exit_with_message
    if not $DEBUG and $!.is_a? Errno::ENOENT
      # If not in Debug mode, do what RGSS would do here to avoid confusion
      filename = $!.message.sub "No such file or directory - ", ""
      print "Unable to find file #{filename}."
      exit_code = 0
    else
      error_message = $DEBUG ? TEMPLATE_DEBUG : TEMPLATE_DEFAULT
      exit_code =
      if $!.message.slice! /\A\(eval((?::\d+){4})?\)(:\d+:in `[^']*')/
        if $1
          top = $1.split ':'
          top.shift
        else
          top = $2
        end
        ErrorParser.fill_template error_message, top
      else
        ErrorParser.fill_template error_message, $!.backtrace[0].dup
      end
      error_message.sub! 'CLASS', $!.class.to_s
      error_message.sub! 'MESSAGE', $!.message
      if error_message['TRACE']
        error_message.sub! 'TRACE', (
          ErrorParser.parse_backtrace($!.backtrace)
        ).join("\n")
      end
      print error_message
    end
    exit! exit_code unless $DEBUG
  end

  # Write the backtrace items into the template
  def self.parse_backtrace trace
    if trace
      trace.collect do |trace_line|
        line = TEMPLATE_TRACE_ENTRY.dup
        ErrorParser.fill_template line, trace_line
        line
      end
    else
      []
    end
  end

  # Transform the entries of caller as well for Debugging
  module ::Kernel
    alias old_caller caller
    def caller
      ErrorParser.parse_backtrace old_caller
    end
  end

  private

  # Fill the error template with values from a backtrace entry
  def self.fill_template template, trace
    if trace.is_a? Array
      source, name, command_id, line_number = trace
      filetype = FILETYPE_EVENT
      line = TEMPLATE_EVENT_LINE
      line.sub! 'COMMAND', command_id
      line.sub! 'LINE', line_number
      sourcetype = SOURCETYPE_MAP
    else
      script_id = trace.slice!(/\ASection(\d+)/) ? $1.to_i : nil
      line = trace.slice!(/\A:(\d+)/) ? $1.to_i : UNKNOWN
      if script_id
        filetype = FILETYPE_SCRIPT
        name = $RGSS_SCRIPTS[script_id][1]
        exit_code =
        if line.is_a? Integer
          if defined? Inserter and Inserter.scripts[script_id]
            Inserter.scripts[script_id].each do |range, place, real_script_id|
              if range === line
                case place[0]
                when :external
                  filetype = FILETYPE_UNKNOWN
                  name = 'inserted script'
                when String
                  filetype = FILETYPE_FILE
                  name = place[0]
                end
                script_id = real_script_id if real_script_id
                line += place[1] - range.begin
                break
              end
            end
          end
          (script_id << 16) + line
        else
          (script_id << 16)
        end
      else
        filetype =
        if trace.slice!(/\A(?:\.\/)?([^:]*)/) != '(eval)'
#        if trace.slice!(/\A(?:\.\/)?([^:]*)/).length > 0
          name = $1
          FILETYPE_FILE
        else
          name = 'evaluated'
          FILETYPE_UNKNOWN
        end
      end
      if trace[/\A:in `(.+)'\z/]
        sourcetype = SOURCETYPE_METHOD
        source = $1
      else
        sourcetype = SOURCETYPE_MAIN
        source = 'main'
      end
    end
    template.sub! 'FILETYPE', (filetype or UNKNOWN)
    template.sub! 'FILENAME', name
    template.sub! 'LINE', line.to_s
    template.sub! 'SOURCETYPE', sourcetype
    template.sub! 'SOURCE', source
    (filetype == FILETYPE_SCRIPT) ? exit_code : 0
  end
end

begin
  if __FILE__[/\ASection(\d{3,})\z/]
    i = $1.to_i + 1
  else
    print 'Error executing the scripts.'
    exit! 0
  end
  while i < $RGSS_SCRIPTS.length
    eval($RGSS_SCRIPTS[i][3], self, sprintf('Section%03d', i), 1)
    i += 1
  end
  exit! 0
rescue ScriptError, StandardError
  ErrorParser.exit_with_message
  #retry
end