---@class Textbox : Object
---
---@field expression Expression
---
---@overload fun(...) : Textbox
local Textbox, super = HookSystem.hookScript(Textbox)

function Textbox:init(x, y, width, height, default_font, default_font_size, battle_box)
    super.init(self, x, y, width, height, default_font, default_font_size, battle_box)
    self.expression = nil

    -- talk sprite state variables
    self.was_skipping = false
    self.was_talking = false
    self.original_sprite = nil
    self.talksprite_active = false

    -- register expression commands
    self.text:registerCommand("expression", function(text, node, dry)
        if not self.expression then return end
        local expr_name = node.arguments[1]
        local part_name = node.arguments[2]
        if expr_name then
            self.expression:setExpression(expr_name, part_name)
            self:updateTextBounds()
        end
    end)

    self.text:registerCommand("expressionc", function(text, node, dry)
        if not self.expression then return end
        local expr_name = node.arguments[1]
        local part_name = node.arguments[2]
        local ox = tonumber(node.arguments[3]) or 0
        local oy = tonumber(node.arguments[4]) or 0

        if expr_name then
            self.expression:setExpression(expr_name, part_name)
        end

        if self.actor then
            local aox, aoy = self.actor:getPortraitOffset()
            ox = ox - aox
            oy = oy - aoy
        end

        self.expression:setPosition(self.face_x + ox, self.face_y + oy)
        self:updateTextBounds()
    end)
end

function Textbox:getActorSpriteBase(act_sprite)
    if not act_sprite.texture_path or not act_sprite.path then return nil end
    local relative = string.sub(act_sprite.texture_path, #act_sprite.path + 2)
    local stripped = relative:match("^(.-)_%d+$")
    return stripped or relative
end

function Textbox:revertTalkSprite(talk_sprite)
    local actor = talk_sprite.actor
    if not actor then return end
    if actor:getDefaultSprite() then
        talk_sprite:setSprite(actor:getDefaultSprite())
    elseif actor:getDefaultAnim() then
        talk_sprite:setAnimation(actor:getDefaultAnim())
    elseif actor:getDefault() then
        talk_sprite:set(actor:getDefault())
    end
    talk_sprite:stop()
end

function Textbox:setActor(actor)
    if self.talksprite_active then
        local talk_sprite = self.text and self.text.talk_sprite
        if talk_sprite then
            self:revertTalkSprite(talk_sprite)
        end
    end

    if self.expression then
        self.expression:remove()
        self.expression = nil
    end

    self.was_talking = false
    self.original_sprite = nil
    self.talksprite_active = false

    super.setActor(self, actor)

    local parts_data = self.actor and self.actor:getExpressionParts()
    if parts_data and next(parts_data) then
        self.expression = Expression(parts_data, self.face_x, self.face_y, self.actor)
        self:addChild(self.expression)
        self.face.visible = false
    else
        self.face.visible = true
    end
end

function Textbox:setFace(face, ox, oy)
    if self.expression then
        local primary = self.expression:getPrimaryPartName()
        if primary then
            self.expression:setPartExpression(primary, face)
        end
        if self.actor then
            local aox, aoy = self.actor:getPortraitOffset()
            ox = (ox or 0) + aox
            oy = (oy or 0) + aoy
        end
        self.expression:setPosition(self.face_x + (ox or 0), self.face_y + (oy or 0))
        self:updateTextBounds()
    else
        super.setFace(self, face, ox, oy)
    end
end

function Textbox:setSize(w, h)
    self.width = w or 0
    self.height = h or 0

    if self.expression then
        self.expression:setPosition(116 / 2, self.height / 2)
    else
        self.face:setPosition(116 / 2, self.height / 2)
    end

    self:updateTextBounds()

    local has_portrait = (self.expression and self.expression.texture) or self.face.texture
    if has_portrait then
        self.box:setSize(self.width - 116, self.height)
    else
        self.box:setSize(self.width, self.height)
    end
end

function Textbox:updateTextBounds()
    local has_portrait = (self.expression and self.expression.texture) or self.face.texture

    if has_portrait then
        self.text.x = self.text_x + 116
        self.text.width = self.width - 116 + self.wrap_add_w
    else
        self.text.x = self.text_x
        self.text.width = self.width + self.wrap_add_w
    end

    if self.text.align == "right" then
        self.text.x = self.text.x - self.wrap_add_w
    end
end

function Textbox:update()
    local state = self.text.state
    local is_talking = state.talk_anim and state.typing and not self.text:isPaused() and (state.waiting == 0)

    if self.expression then
        if is_talking then
            if not self.expression.talking then
                self.expression:play()
            end
        else
            self.expression:stop()
        end
    end

    -- swap to talk sprite
    local talk_sprite = self.text.talk_sprite
    if talk_sprite and talk_sprite.actor then
        local actor = talk_sprite.actor
        local going_active = is_talking and not self.was_talking
        local going_idle = (not is_talking) and self.was_talking

        if going_active then
            if not self.talksprite_active then
                local base = self:getActorSpriteBase(talk_sprite)
                local entry = actor:getTalkSprite(base)
                if entry then
                    self.original_sprite = base
                    self.talksprite_active = true
                    talk_sprite:setSprite(entry[1])
                    talk_sprite:play(entry[2])
                end
            else
                -- resume talksprite if it weas paused
                local entry = actor:getTalkSprite(self.original_sprite)
                if entry then
                    talk_sprite:play(entry[2])
                end
            end

        elseif going_idle and self.talksprite_active then
            -- pause talksprite if skipping dialogue
            if self.was_skipping then
                talk_sprite:stop()
            else
                self:revertTalkSprite(talk_sprite)
                self.talksprite_active = false
                self.original_sprite = nil
            end
        end

        self.was_talking = is_talking
        self.was_skipping = state.skipping
    else
        self.was_talking = false
        self.was_skipping = false
        if self.talksprite_active then
            self.talksprite_active = false
            self.original_sprite = nil
        end
    end

    super.update(self)
end

return Textbox