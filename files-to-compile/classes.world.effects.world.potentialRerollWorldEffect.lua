local t = {}
local abstractUpgradeMonsterAfterPlayerStepsWorldEffect = require("classes.world.effects.world.abstractUpgradeMonsterAfterPlayerStepsWorldEffect")

function t:new(_saveableOptions, _monster)
  local effect = abstractUpgradeMonsterAfterPlayerStepsWorldEffect:new(_saveableOptions, _monster, 5)
  effect.classes.potentialRerollWorldEffect = true
  if _monster then
    local _monster = _monster
    _saveableOptions.originalPotential = _monster:getPotential()
    _monster:setDidRerollPotential()
    _monster:setPotential(_monster:rerollPotential())
  end
  
  function effect:getClassPath()
    return "classes.world.effects.world.potentialRerollWorldEffect"
  end
  
  function effect:getReachedTargetPlayerStepsPhoneMessageUID()
    return "electricTown_OLEG.reroll_ready"
  end
  
  function effect:getOriginalPotential()
    return _saveableOptions.originalPotential
  end
  
  return effect
end

return t
