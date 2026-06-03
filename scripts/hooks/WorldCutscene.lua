---@class WorldCutscene : Cutscene
---
---@overload fun(world: World, group: string, id?: string, ...) : WorldCutscene
local WorldCutscene, super = HookSystem.hookScript(WorldCutscene)

---@param text string|string[]
---@param portrait (string|table|ExpressionPart)?
---@param actor Character|Actor|string?
---@param options table?
function WorldCutscene:text(text, portrait, actor, options)
    if type(actor) == "table" and not isClass(actor) then
        options = actor
        actor   = nil
    end

    local is_part  = isClass(portrait) and portrait:includes(ExpressionPart)
    local is_table = type(portrait) == "table" and not isClass(portrait)

    local actor_has_expression = false
    if is_table then
        if type(actor) == "string" then
            actor = self:getCharacter(actor) or actor
        end

        actor = actor or self.textbox_actor

        if isClass(actor) and actor:includes(Character) then
            actor = actor.actor
        end

        if isClass(actor) and actor:includes(Actor) then
            local parts = actor:getExpressionParts()
            actor_has_expression = parts and next(parts) and true or false
        end
    end

    if not is_part and not (actor_has_expression) then
        return super.text(self, text, portrait, actor, options)
    end

    options = options or {}

    -- we need to pass wait as false when calling super.text() so the script doesnt get yielded
    -- idk if this is considered hacky or not
    local wait = options["wait"]
    options["wait"] = false

    local finished = super.text(self, text, nil, actor, options)

    if is_part then
        -- if we provide an ExpressionPart as the portrait argument then we make a new temporary expression object
        -- instead of using the existing one (if it exists)
        if self.textbox.expression then
            self.textbox.expression:remove()
        end

        local name = portrait.name or "face"
        local temp = Expression({}, self.textbox.face_x, self.textbox.face_y, self.textbox.actor)
        temp:addExpressionPart(name, portrait)
        temp:setPrimaryPart(name)

        self.textbox.expression = temp
        self.textbox:addChild(temp)
        self.textbox.face.visible = false

        if portrait.default then
            temp:setPartExpression(name, portrait.default)
        end

        self.textbox:setFace(nil, options["x"], options["y"])
    elseif is_table then
        -- temporarily apply new values to fields of each expression part
        if self.textbox.expression then
            for part_name, overrides in pairs(portrait) do
                local part = self.textbox.expression.parts[part_name]
                if part and type(overrides) == "table" then
                    part:applyOverrides(overrides)
                end
            end
            self.textbox:updateTextBounds()
        end
    end

    -- redo the original wait logic
    local should_wait = wait or wait == nil
    if not self.textbox.text.can_advance then
        should_wait = wait
    end

    if should_wait then
        return self:wait(finished)
    else
        return finished, self.textbox
    end
end

return WorldCutscene
