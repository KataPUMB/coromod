local t = {}
local abstractUpgradeMonsterAfterPlayerStepsWorldEffect = require("classes.world.effects.world.abstractUpgradeMonsterAfterPlayerStepsWorldEffect")

function t:new(_saveableOptions, _monster)
  local effect = abstractUpgradeMonsterAfterPlayerStepsWorldEffect:new(_saveableOptions, _monster, 5)
  effect.classes.spinnerSwapWorldEffect = true
  
  function effect:getReachedTargetPlayerStepsPhoneMessageUID()
    return "desertTown_KERRIN.spinnerSwap_ready"
  end
  
  function effect:getClassPath()
    return "classes.world.effects.world.spinnerSwapWorldEffect"
  end
  
  return effect
end

return t
