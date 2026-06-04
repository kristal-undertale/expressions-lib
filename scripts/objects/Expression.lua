--- Custom object that acts as a replacement to portraits.
---
---@class Expression : Object
---
---@field part_data table
---@field actor Actor
---
---@field blink_speed number
---@field blink_delay number|table
---@field talk_speed number
---
---@field talking boolean
---@field texture boolean
---@field parts table
---@field blink_state table
---
---@overload fun(...) : Expression
local Expression, super = Class(Object, "Expression")

---@param data table
---@param x number
---@param y number
---@param actor Actor
function Expression:init(data, x, y, actor)
    super.init(self, x or 0, y or 0)

    --// data
    self.part_data = data
    self.actor = actor

    self.blink_speed = (actor and actor.blink_speed) or (4/30)
    self.blink_delay = (actor and actor.blink_delay) or {1, 3}
    self.talk_speed  = (actor and actor.talk_speed) or (4/30)

    --// state variables
    -- true when dialogue is playing, false when not
    self.talking = false
    -- true when texture is loaded, used for the textbox to detect that a portrait exists
    self.texture = nil
    -- has the actual expression parts
    self.parts = {}
    self.primary_part = nil

    -- load
    for name, part_data in pairs(data) do
        local part = ExpressionPart(part_data.path, part_data.x, part_data.y, part_data.options)
        self:addExpressionPart(name, part)
        if part.default then
            part:loadSprite(part.default)
        end
    end
end

---@param name string
---@param part ExpressionPart
function Expression:addExpressionPart(name, part)
    part.expression = self
    self.parts[name] = part
    self:addChild(part.sprite)
    part.blink_state.timer = part:pickBlinkDelay()
end

---@return string?
function Expression:getPrimaryPartName()
    if self.primary_part and self.parts[self.primary_part] then return self.primary_part end
    if self.parts["face"] then return "face" end
    for name in pairs(self.parts) do return name end
    return nil
end

---@param name string
function Expression:setPrimaryPart(name)
    self.primary_part = name
end

---@param part string
---@param expression string
function Expression:loadPartSprite(part, expression)
    local epart = self.parts[part]
    if epart then
        epart:loadSprite(expression)
    end
end

---@param part string
---@param expression string
function Expression:setPartExpression(part, expression)
    local epart = self.parts[part]
    if epart then
        epart:setExpression(expression)
    end
end

---@param expression string
---@param part string
function Expression:setExpression(expression, part)
    local target = part or self:getPrimaryPartName()
    if target then
        self:setPartExpression(target, expression)
    end
end

function Expression:stop()
    if self.talking then
        for _, part in pairs(self.parts) do
            if not part.blink_state.is_blinking then
                part.blink_state.timer = part:pickBlinkDelay()
            end
        end
    end
    self.talking = false
    for _, part in pairs(self.parts) do
        part:stop()
    end
end

---@param speed number?
function Expression:play(speed)
    self.talking = true
    for _, part in pairs(self.parts) do
        part:play(speed)
    end
end

function Expression:blink()
    for _, part in pairs(self.parts) do
        local state = part.blink_state
        if state.current_expr and state.has_blink and not state.is_blinking then
            part.sprite:setSprite(part.path .. "/" .. state.current_expr .. "_blink")
            part.sprite:play(part:getBlinkSpeed())
            state.is_blinking = true
            state.timer = state.blink_duration
        end
    end
end

function Expression:update()
    super.update(self)
    for _, part in pairs(self.parts) do
        part:update()
    end
end

return Expression
