require 'tk'
require 'socket'
require_relative 'robotscript'

class Gui

  def initialize

    @traject = {}
    @trajectory_points = {}
    @movement = {'linear' => '1', 'joint-space' => '2' ,'constant tool speed' => '3'}
    @socket = Socket.new Socket::AF_INET, Socket::SOCK_STREAM
    #@socket.connect Socket.pack_sockaddr_in(30001, "192.168.0.110")
    @final_trajectory = []

  end

  def get_coordinates

    x = @x.get().to_f
    y = @y.get().to_f
    z = @z.get().to_f
    rx = @rx.get().to_f
    ry = @ry.get().to_f
    rz = @rz.get().to_f

    return x, y, z, rx, ry, rz

  end

  def get_point_name

    return @entry1.get('1.0', 'end-1c')

  end

  def get_params

    a = @a.get().to_f
    v = @v.get().to_f
    t = @t.get().to_f
    b = @b.get().to_f

    return a, v, t, b

  end

  def insert_to_trajectory

    point, movement = get_listbox_value(@points_list)
    @trajectory.insert('end', movement + ' to: ' + point)
    a, v, t, b = get_params()
    @traject[point] = [@trajectory_points[point], movement, a, v, t, b]
    @final_trajectory << [movement, @trajectory_points[point], a, v, t, b]

  end

  def insert_sleep(sleep_time)

    @trajectory.insert('end', "sleep: #{sleep_time} [s]")
    @final_trajectory << ['sleep', sleep_time]

  end

  def insert_dig_out(dig_out)

    @trajectory.insert('end' , "digital out(7) : #{dig_out}")
    @final_trajectory << ['dig_out', dig_out]

  end

  def get_listbox_value(list)

    return list.get('anchor'), @movement.value

  end

  def save_points

    x, y, z, rx, ry, rz = get_coordinates()
    point_name = get_point_name()
    @trajectory_points[point_name] = [x, y, z, rx, ry, rz]
    @points_list.delete(0, 'end')

    @trajectory_points.keys.each do |point_name|
      @points_list.insert('end', point_name)
    end

  end

  def move_to_position()

    x, y, z, rx, ry, rz = get_coordinates()
    p = [x/1000, y/1000, z/1000, rx, ry, rz]
    script = RobotScript.new('prog', @socket)
    script.add_movel(p, v=2, a=2, t=2, b=0)
    script.add_sleep(1)
    script.execute()

  end

  def generate_trajectory()

    p @final_trajectory

    script = RobotScript.new('prog', @socket)

    if @cont == 1
      script.script += "  while (True):\n"
    end

    @final_trajectory.each do |array|

      a = array[2]
      v = array[3]
      t = array[4]
      b = array[5]

      if array[0] == 'linear'
        script.add_movel(array[1].each_with_index.map{|elem, i| i < 3 ? elem / 1000 : elem }, a, v, t, b)
      elsif array[0] == 'joint-space'
        script.add_movej(array[1].each_with_index.map{|elem, i| i < 3 ? elem / 1000 : elem }, a, v, t, b)
      elsif array[0] == 'constant speed'
        script.add_movep(array[1].each_with_index.map{|elem, i| i < 3 ? elem / 1000 : elem }, a, v, t, b)
      elsif array[0] == 'sleep'
        script.add_sleep(array[1])
      elsif array[0] == 'dig_out'
        script.add_digital_out(array[1])
      end

    end

    if @cont == 1
      script.script += "  end\n"
    end

    script.execute()

  end

  def delete_from_trajectory

    deleted = @trajectory.get('anchor')
    index = @trajectory.curselection
    if !index.empty?
      @final_trajectory.delete_at(index[0])
    end
    @traject.delete(deleted)
    @trajectory.delete('anchor')

  end

  def delete_from_points

    deleted = @points_list.get('anchor')
    @trajectory_points.delete(deleted)
    @points_list.delete('anchor')

  end

  def stop

    p @trajectory.get(0)
    script = RobotScript.new('prog', @socket)
    script.execute()

  end

  def show

    root = TkRoot.new(:title => "UR_App", :width => 700, :height => 900)

    f1 = TkFrame.new(root, :relief => 'sunken', :padx => 25, :pady => 10).grid('row' => 0, 'column' => 0)

    lbl = TkLabel.new(f1, :text => 'X:').pack
    @x = TkSpinbox.new(f1, :font => 12, :width => 7, :to => 100, :from => 0, :increment => 1, :command => proc{move_to_position}).pack('side' => 'top')
    @x.set(0)

    lbl = TkLabel.new(f1, :text => 'Y:').pack
    @y = TkSpinbox.new(f1, :font => 12, :width => 7, :to => 200, :from => -200, :increment => 1, :command => proc{move_to_position}).pack
    @y.set(-200)

    lbl = TkLabel.new(f1, :text => 'Z:').pack
    @z = TkSpinbox.new(f1, :font => 12, :width => 7, :to => 700, :from => 250, :increment => 10, :command => proc{move_to_position}).pack
    @z.set(450)

    f2 = TkFrame.new(root, :relief => 'sunken', :padx => 25, :pady => 10).grid('row' => 0, 'column' => 2)

    lbl = TkLabel.new(f2, :text => 'RX:').pack
    @rx = TkSpinbox.new(f2, :font => 12, :width => 7, :to => 3, :from => -3, :increment => 0.1, :command => proc{move_to_position}).pack
    @rx.set(0)

    lbl = TkLabel.new(f2, :text => 'RY:').pack
    @ry = TkSpinbox.new(f2, :font => 12,:width => 7, :to => 3, :from => -3, :increment => 0.1, :command => proc{move_to_position}).pack
    @ry.set(-3.14)

    lbl = TkLabel.new(f2, :text => 'RZ:').pack
    @rz = TkSpinbox.new(f2, :font => 12, :width => 7, :to => 3, :from => -3, :increment => 0.1, :command => proc{move_to_position}).pack
    @rz.set(0)

    f1_2 = TkFrame.new(root, :relief => 'sunken', :padx => 25, :pady => 10).grid('row' => 0, 'column' => 1)
    btn_move = TkButton.new(f1_2, :text => "Move to \n current position", :command => proc{move_to_position}).pack('side' => 'top', :pady => 5)

    f4 = TkFrame.new(root, :relief => 'sunken', :pady => 20, ).grid('row' => 1, 'column' => 1)
    lbl = TkLabel.new(f4, :text => 'Point name:',).pack(:pady => 5)
    @entry1 = TkText.new(f4, :font => 12, :width => 15, :height => 1).pack()
    btn_add = TkButton.new(f4, :text => "Save position",  :command => proc{save_points}).pack(:pady => 5)

    f5 = TkFrame.new(root, :relief => 'sunken',).grid('row' => 2, 'column' => 0)
    @points_list = TkListbox.new(f5, :width => 15, :height => 12, :listvariable => @trajectory_points).pack()

    f6 = TkFrame.new(root, :relief => 'sunken',).grid('row' => 2, 'column' => 1)
    push_btn = TkButton.new(f6, :text => '>>', :command => proc{insert_to_trajectory()}).pack()
    @movement = TkVariable.new
    @movement.value = 'linear'

    linear_mov_btn = TkRadioButton.new(f6, :text => 'linear', :variable => @movement, :value => 'linear').pack()
    joint_mov_btn = TkRadioButton.new(f6, :text => 'joint-space', :variable => @movement, :value => 'joint-space').pack()
    constant_spd_btn = TkRadioButton.new(f6, :text => 'constant tool speed', :variable => @movement, :value => 'constant speed').pack()

    lbl = TkLabel.new(f6, :text => 'a:').pack('side' => 'left')
    @a = TkSpinbox.new(f6, :font => 12, :width => 3, :from => 0, :to => 10, :increment => 0.1).pack('side' => 'left')
    @a.set(2)

    lbl = TkLabel.new(f6, :text => 'v:').pack('side' => 'left')
    @v = TkSpinbox.new(f6, :font => 12, :width => 3, :from => 0, :to => 10, :increment => 0.1).pack('side' => 'left')
    @v.set(2)

    lbl = TkLabel.new(f6, :text => 't:').pack('side' => 'left')
    @t = TkSpinbox.new(f6, :font => 12, :width => 3, :from => 0, :to => 10, :increment => 0.1).pack('side' => 'left')
    @t.set(2)

    lbl = TkLabel.new(f6, :text => 'b:').pack('side' => 'left')
    @b = TkSpinbox.new(f6, :font => 12, :width => 3, :from => 0, :to => 10, :increment => 0.1).pack
    @b.set(0)

    f7 = TkFrame.new(root, :relief => 'sunken',).grid('row' => 2, 'column' => 2)
    @trajectory = TkListbox.new(f7, :width => 20, :height => 12, :listvariable => @traject).pack()

    f9 = TkFrame.new(root, :relief => 'sunken', :pady => 20, ).grid('row' => 3, 'column' => 2)
    delete_btn = TkButton.new(f7, :text => 'delete', :command => proc{delete_from_trajectory()}).pack()
    @cont = TkVariable.new(0)
    @run_cont = TkCheckButton.new(f9, :text => 'Run continously', :height => 2, :width => 20, :variable => @cont, :indicatoron => 'true').pack()
    generate_btn = TkButton.new(f9, :text => 'generate trajectory', :command => proc{generate_trajectory()}).pack()

    f10 = TkFrame.new(root, :relief => 'sunken', :pady => 20, ).grid('row' => 3, 'column' => 1)

    lbl = TkLabel.new(f10, :text => 'sleep:').pack
    @sleep = TkSpinbox.new(f10, :font => 12, :width => 3, :from => 0, :to => 10, :increment => 0.1).pack
    add_sleep = TkButton.new(f10, :text => 'add sleep', :command => proc{insert_sleep(@sleep.get().to_f)}).pack()

    lbl = TkLabel.new(f10, :text => 'digital_output:').pack
    @dig_out = TkCombobox.new(f10, :font => 12, :width => 5, :values => ['true', 'false']).pack
    @dig_out.set('true')

    add_dig_out = TkButton.new(f10, :text => 'add digital out', :command => proc{insert_dig_out(@dig_out.get())}).pack()
    stop_btn = TkButton.new(f9, :text => 'STOP' , :command => proc{stop()}).pack()

    f11 = TkFrame.new(root, :relief => 'sunken').grid('row' => 3, 'column' => 0)
    del_btn = TkButton.new(f5, :text => 'delete', :command => proc{delete_from_points()}).pack()

    scroll = TkScrollbar.new(f5) do
       orient 'vertical'
       place('height' => 180, 'x' => 110)
    end

    @points_list.yscrollcommand(proc { |*args|
       scroll.set(*args)
    })

    scroll.command(proc { |*args|
       @points_list.yview(*args)
    })

    scroll_2 = TkScrollbar.new(f7) do
       orient 'vertical'
       place('height' => 180, 'x' => 150)
    end

    @trajectory.yscrollcommand(proc { |*args|
       scroll_2.set(*args)
    })

    scroll_2.command(proc { |*args|
       @trajectory.yview(*args)
    })

    Tk.mainloop

  end

end
