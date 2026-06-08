local Text, super = HookSystem.hookScript(Text)

--- Settings for a font asset, paired with the actual font data as a .json file.
---@class Assets.font_settings
---@field offset number[]? # X & Y offsets for the font.
function Text:getCharPosition(node, state)
    local x, y = super.getCharPosition(self, node, state)
    local font_data = Assets.getFontData(state.font)
    if font_data.offset then
        x = x + (font_data.offset[1] or 0)
        y = y + (font_data.offset[2] or 0)
    end
    return x, y
end

return Text
