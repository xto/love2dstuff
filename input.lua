InputHandler = {}

function InputHandler:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  return o
end

function InputHandler:mousemoved(x, y)
end

function InputHandler:mousereleased(x, y, button, istouch)
  local posx, posy = viewport:screenToMap(x, y)
  if button == 1 then
    -- TODO might run this through player control
    bus:fire("viewport.clicked", {button=button, x=posx, y=posy})
  elseif button == 2 then
    if self.selected then
      self.control:issueCommand(self.selected, {action='move', pos={x=posx, y=posy}})
    end
  end
end

function InputHandler:keypressed(key, scancode, isrepeat)
  if scancode == 'escape' then
    love.event.quit()
  end
  if scancode == 'return' then
    self:handleEndTurn()
  end
end

function InputHandler:handleEndTurn()
  local predicate = function(comp)
    return comp.points.left > 0
  end
  local entities = self.entityManager:getComponentsByType({owner=ownedBy(self.player)}, {action=predicate}, position, selectable)

  for id, comps in pairs(entities) do
    self.selectionManager:select(id)
    if (#comps.action.queue) > 0 or comps.action.current then
      self.control:simulate(id)
    else
      return
    end
  end

  self.control:endTurn()
end

function InputHandler:onSelected(e)
  self.selected = e.id
end

function InputHandler:onDeselected(e)
  self.selected = nil
end