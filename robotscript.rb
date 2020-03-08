
class RobotScript


  attr_accessor :script

  def initialize(name, socket)

    @name = name
    @s = socket
    @pre = "def %{name}():\n" % {name: name}
    @script = ""
    @post = "end\n"
    @loaded = false

  end

  def load_script(filename)

    File.readlines(filename).each do |line|
      @script += line
    end

    @loaded = True

  end

  def get_script()

    if @loaded
      return @script
    else
      return @pre + @script + @post
    end

  end

  def add_message(message)

    cmd = "  textmsg(%{message})" % {message: message}
    @script += cmd

  end

  def add_movep(p, v, a, t, b)

    cmd = "  movep(p%{p}, %{a}, %{v}, %{b})\n" % {p: p, v: v, a: a, t: t, b: b}
    @script += cmd

  end

  def add_movel(p, v, a, t, b)

    cmd = "  movel(p%{p}, %{a}, %{v}, %{t}, %{b})\n" % {p:p , v:v, a: a, t: t, b: b}
    @script += cmd

  end

  def add_movej(p, a, v, t, b)

    cmd = "  movej(p%{p}, %{a}, %{v}, %{t}, %{b})\n" % {p:p , v:v, a: a, t: t, b: b}
    @script += cmd

  end

  def add_digital_out(x)

    cmd = "  set_digital_out(7,%{x})\n" % {x: x}
    @script += cmd

  end

  def add_sleep(s)

    cmd = "  sleep(%{s})\n" % {s: s}
    @script += cmd

  end

  def send_script(socket, script)

    socket.send(script,0)

  end

  def save(filename, contents)

    File.open(filename, 'w') do |file|
      file.write(contents)
    end

  end

  def home_position(program)

    program.add_movel([0.0, -0.160, 0.450, 0, -3.14, 0], 2, 2, 2, 0.0)
    program.add_sleep(1)

  end

  def execute()

      @script = get_script()
      save('script.txt', @script)
      #send_script(@s, @script)
      @script = ""

  end

end
