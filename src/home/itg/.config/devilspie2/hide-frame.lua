-- hide-frame.lua

if (get_window_name() == "Simply Love") then
    undecorate_window()

    -- We'll check up to 10 times (1s apart) to ensure it's at (0,0)
    for i = 1, 10 do
        local x = get_window_x()
        local y = get_window_y()

        if x ~= 0 or y ~= 0 then
            set_window_position(0, 0)
            os.execute("sleep 1")
        end
    end
end

