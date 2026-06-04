--- A single Expression part.
---
---@class ExpressionPart : Class
---
---@field path string
---@field x number
---@field y number
---@field layer number
---@field default string?
---
---@field blink_speed number?
---@field blink_delay (number|table)?
---@field talk_speed number?
---
---@field sprite Sprite
---@field blink_state table
---@field expression Expression
---
---@overload fun(...) : ExpressionPart
local ExpressionPart = Class()

---@param path string
---@param x number
---@param y number
---@param options table?
function ExpressionPart:init(path, x, y, options)
    options = options or {}

    --// data
    self.path = path
    self.x = x or 0
    self.y = y or 0
    self.layer = options.layer or 0
    self.default = options.default

    -- optional overrides
    self.blink_speed = options.blink_speed
    self.blink_delay = options.blink_delay
    self.talk_speed = options.talk_speed

    -- more data
    self.sprite = Sprite(nil, self.x, self.y)
    self.sprite:setScale(2, 2)
    self.sprite.layer = self.layer

    self.blink_state = {
        current_expr = nil,
        timer = 0,
        is_blinking = false,
        has_blink = false,
        blink_duration = 0,
    }

    self.expression = nil
end

---@return number blink_speed
function ExpressionPart:getBlinkSpeed()
    if self.blink_speed ~= nil then return self.blink_speed end
    return self.expression.blink_speed
end

---@return number blink_delay
function ExpressionPart:getBlinkDelay()
    if self.blink_delay ~= nil then return self.blink_delay end
    return self.expression.blink_delay
end

---@return number talk_speed
function ExpressionPart:getTalkSpeed()
    if self.talk_speed ~= nil then return self.talk_speed end
    return self.expression.talk_speed
end

---@return number
function ExpressionPart:pickBlinkDelay()
    local blink_delay = self:getBlinkDelay()
    if type(blink_delay) == "table" then
        local min_f = blink_delay[1] * 30
        local max_f = blink_delay[2] * 30
        return min_f + math.random() * (max_f - min_f)
    else
        return blink_delay * 30
    end
end

---@param expression string
---@return boolean has_blink
---@return number blink_duration
function ExpressionPart:checkBlinkFrames(expression)
    local blink_path = self.path .. "/" .. expression .. "_blink"
    local frames = Assets.getFramesOrTexture(blink_path)
    if not frames or #frames == 0 then
        return false, 0
    end

    local duration_frames = self:getBlinkSpeed() * #frames * 30
    return true, duration_frames
end

---@param expression string
function ExpressionPart:loadSprite(expression)
    if not expression then return end
    local state = self.blink_state

    state.current_expr = expression
    state.is_blinking = false
    state.timer = self:pickBlinkDelay()
    self.sprite:setSprite(self.path .. "/" .. expression)
    state.has_blink, state.blink_duration = self:checkBlinkFrames(expression)
    self.expression.texture = true
end

---@param expression string
function ExpressionPart:setExpression(expression)
    if not expression then return end
    local state = self.blink_state

    state.current_expr = expression
    state.is_blinking = false
    state.timer = self:pickBlinkDelay()

    self.sprite:setSprite(self.path .. "/" .. expression)
    self.sprite:play(self:getTalkSpeed())
    self.expression.talking = true

    state.has_blink, state.blink_duration = self:checkBlinkFrames(expression)
    self.expression.texture = true
end

---@param speed number
function ExpressionPart:play(speed)
    speed = speed or self:getTalkSpeed()
    local state = self.blink_state

    if state.is_blinking and state.current_expr then
        self.sprite:setSprite(self.path .. "/" .. state.current_expr)
        state.is_blinking = false
    end
    state.timer = self:pickBlinkDelay()

    if state.current_expr and not state.is_blinking then
        self.sprite:play(speed)
    end
end

function ExpressionPart:stop()
    if not self.blink_state.is_blinking then
        self.sprite:stop()
    end
end

function ExpressionPart:update()
    local blink_speed = self:getBlinkSpeed()
    local blink_delay = self:getBlinkDelay()
    local do_blink = blink_speed > 0 and (type(blink_delay) == "table" or blink_delay > 0)
    if not do_blink then return end

    local state = self.blink_state
    if state.current_expr and state.has_blink then
        local sprite = self.sprite

        if self.expression.talking then
            state.timer = self:pickBlinkDelay()
            if state.is_blinking then
                sprite:setSprite(self.path .. "/" .. state.current_expr)
                sprite:stop()
                state.is_blinking = false
            end
        else
            state.timer = state.timer - DTMULT

            if state.timer <= 0 then
                if state.is_blinking then
                    sprite:setSprite(self.path .. "/" .. state.current_expr)
                    sprite:stop()
                    state.is_blinking = false
                    state.timer = self:pickBlinkDelay()
                else
                    local blink_path = self.path .. "/" .. state.current_expr .. "_blink"
                    sprite:setSprite(blink_path)
                    sprite:play(blink_speed)
                    state.is_blinking = true
                    state.timer = state.blink_duration
                end
            end
        end
    end
end

---@param overrides table
function ExpressionPart:applyOverrides(overrides)
    for key, value in pairs(overrides) do
        if key == "sprite" then
            self:setExpression(value)
        elseif key == "alpha" then
            self.sprite.alpha = value
        else
            self[key] = value
        end
    end
end

return ExpressionPart
