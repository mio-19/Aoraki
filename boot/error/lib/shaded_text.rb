# This only works as long as the elements are not in a layout.
class ShadedText
  OFFSET = 2

  def initialize(*args, size: nil, line_space: nil)
    @secondary = LVGL::LVLabel.new(*args)
    sec_style = @secondary.get_style(LVGL::LABEL_STYLE::MAIN).dup
    @secondary.set_style(LVGL::LABEL_STYLE::MAIN, sec_style)
    sec_style.text_color = 0xFF000000

    @main = LVGL::LVLabel.new(*args)
    main_style = @main.get_style(LVGL::LABEL_STYLE::MAIN).dup
    @main.set_style(LVGL::LABEL_STYLE::MAIN, main_style)
    main_style.text_color = 0xFFFFFFFF

    if size
      font = LVGUI::Fonts.primary(size)
      sec_style.text_font = font
      main_style.text_font = font
    end

    if line_space
      sec_style.text_line_space = line_space
      main_style.text_line_space = line_space
    end

    # Ensures the position is reset at least once, to sync-up the shade.
    set_pos(0, 0)
  end

  def method_missing(*args)
    @main.send(*(args.dup))
    @secondary.send(*(args.dup))
  end

  def set_pos(x, y)
    @main.set_pos(x, y)
    @secondary.set_pos(x+OFFSET, y+OFFSET)
  end

  def set_x(value)
    @main.set_x(value)
    @secondary.set_x(value+OFFSET)
  end

  def set_y(value)
    @main.set_y(value)
    @secondary.set_y(value+OFFSET)
  end
end
