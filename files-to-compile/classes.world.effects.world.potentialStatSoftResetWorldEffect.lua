local t = {}
local abstractUpgradeMonsterAfterPlayerStepsWorldEffect = require("classes.world.effects.world.abstractUpgradeMonsterAfterPlayerStepsWorldEffect")

function t:new(_saveableOptions, _monster)
  local effect = abstractUpgradeMonsterAfterPlayerStepsWorldEffect:new(_saveableOptions, _monster, 5)
  effect.classes.potentialStatSoftResetWorldEffect = true
  
  function effect:getReachedTargetPlayerStepsPhoneMessageUID()
    return "ghostTown_ASHTON.potentialStatReset_ready"
  end
  
  function effect:getClassPath()
    return "classes.world.effects.world.potentialStatSoftResetWorldEffect"
  end
  
  return effect
end

return t
