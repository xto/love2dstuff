ActionComponent = {}

function ActionComponent:new(points)
  local o = {}
  setmetatable(o, self)
  self.__index = self

  o.points = {}
  o.active = false -- do we want to simulate this?
  o.points.left = 0 -- How many points are available in this turn?
  o.points.max = points
  o.points.needed = 0 -- How many points are needed to finish this action?
  o.points.timePerPoint = 0.0 -- How much time should be spent per step consuming action points?
  o.points.consumesPoints = 1 -- How many points to consume in each step?
  o.func = nil -- Function to call on each step
  o.queue = {}
  o.time = 0
  o.current = nil

  return o
end

function ActionComponent:enqueue(cmd)
  table.insert(self.queue, cmd)
end

function ActionComponent:execute()
  if self.points.left == 0 then return end
  if (not self.current) and (#self.queue) == 0 then return end

  if not self.current then
    _, self.current = next(self.queue)
  end

  local requiredPoints = 0
  local timePerPoint = 0
  local consumesPoints = 1
  local action = self.current.action
  if action == 'nothing' then
    requiredPoints = self.points.left
    consumesPoints = requiredPoints
  elseif action == 'found_colony' then
    requiredPoints = self.points.left
    consumesPoints = requiredPoints
  elseif action == 'move' then
    -- TODO: we should calculate the lenght of the path and estimate the required points based of that.
    requiredPoints = self.current.path.length
    timePerPoint = .2
  end

  self.points.needed = requiredPoints
  self.points.timePerPoint = timePerPoint
  self.points.consumesPoints = consumesPoints
end

function ActionComponent:consumePoint(entity)
  if self.points.left == 0 then return end
  if self.points.left < self.points.consumesPoints then return end

  self.points.left = self.points.left - self.points.consumesPoints
  self.points.needed = self.points.needed - self.points.consumesPoints
end

function ActionComponent:complete()
  self.points.needed = 0
end

function ActionComponent:isComplete()
  return self.points.needed <= 0
end

function ActionComponent:hasCommand()
  return self.current or (#self.queue) > 0
end

--- Called when the current command is done.
function ActionComponent:cleanup()
  local id, _ = next(self.queue)
  self.current = nil
  table.remove(self.queue, id)
  self.points.needed = 0
end

function ActionComponent:replenish()
  self.points.left = self.points.max
end

function ActionComponent:hasPointsLeft()
  return self.points.left > 0
end
