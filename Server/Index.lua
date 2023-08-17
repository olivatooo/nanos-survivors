XPPickUpRange = 300
Package.Require("Skills.lua")

GameStates = {
  Playing = 1,
  Waiting = 1,
}

NanoSurvivors = {
  CurrentXP = 0,
  MaxXP = 5,
  CurrentLevel = 1,
  GameState = GameStates.Waiting
}


Levels = {
  [1] = {
  }
}

MainChar = nil

function SpawnPlayer(player, location, rotation)
  -- Spawns a new Character for the Player
  local new_char = Character(location or Vector(), rotation or Rotator(), "nanos-world::SK_Male",
    CollisionType.IgnoreOnlyPawn)
  new_char:SetFallDamageTaken(0)
  player:Possess(new_char)
  new_char:SetViewMode(ViewMode.TopDown)
  new_char:SetTeam(1)
  new_char:Subscribe("TakeDamage", function(self, damage, bone, dtype, from_direction, instigator, causer)
    if DamageType.Explosion == dtype or DamageType.Shot == dtype then
      return false
    end
  end)

  new_char:Subscribe("Death",
    function(self, last_damage_taken, last_bone_damaged, damage_type_reason, hit_from_direction, instigator, causer)
      self:Destroy()
    end)
  local weapon = AK47()
  weapon:SetDamage(1)
  weapon:SetSpread(-20)
  weapon:SetAmmoSettings(100000, 100000)
  new_char:PickUp(weapon)

  MainChar = new_char
end

-- When Player Connects, spawns a new Character and gives it to him
Player.Subscribe("Spawn", function(player)
  Server.BroadcastChatMessage("<cyan>" .. player:GetName() .. "</> has joined the struggle")

  SpawnPlayer(player)
end)

Package.Subscribe("Load", function()
  for k, player in pairs(Player.GetAll()) do
    SpawnPlayer(player)
  end
end)

function SpawnEnemies()
  -- TODO better algorithm
  local amount_of_enemies = math.random(NanoSurvivors.CurrentLevel)

  for k = 1, amount_of_enemies do
    SpawnEnemy()
  end
end

function GetRandomHero()
  return Player.GetAll()[math.random(#Player.GetAll())]:GetControlledCharacter()
end

function SpawnEnemy()
  -- choose one player
  -- spawn outside screen all players
  -- random location

  -- Maybe get zombie spawn locations in map?
  local distance_to_spawn = Vector(1500, 1500, 0)

  -- TODO get near player
  local near_player_character = GetRandomHero()

  -- Gets random location around the player to spawn the enemy
  local random_rotation = Rotator.Random()
  random_rotation.Pitch = 0
  local enemy_location = near_player_character:GetLocation() + random_rotation:RotateVector(distance_to_spawn)

  -- TODO get enemy health
  -- TODO random groan
  local health = (math.random(NanoSurvivors.CurrentLevel) * #Player.GetAll())
  local meshes = {
    "zombie-pack-v1::SK_ZombieAB_a",
    "zombie-pack-v1::SK_ZombieAB_b",
    "zombie-pack-v1::SK_ZombieAC_A",
    "zombie-pack-v1::SK_ZombieAC_B",
    "zombie-pack-v1::SK_ZombieAD_One",
    "zombie-pack-v1::SK_ZombieAD_OneMesh",
    "zombie-pack-v1::SK_ZombieAEv1",
    "zombie-pack-v1::SK_ZombieAEv2",
  }
  local enemy = Character(enemy_location, Rotator(), meshes[math.random(#meshes)], CollisionType.Normal, true, health)
  enemy:SetTeam(2)
  enemy:SetFallDamageTaken(0)
  enemy:SetImpactDamageTaken(0)
  -- TODO: Special zombies?
  -- Scrap this off?
  -- Create super zombies
  if math.random(100) > (100 - NanoSurvivors.CurrentLevel) then
    enemy:SetHealth(NanoSurvivors.CurrentLevel * 10)
    enemy:SetScale(Vector((NanoSurvivors.CurrentLevel / 10) + 2))
    enemy:SetMaterialColorParameter("Tint", Color(255, 0, 0))
  end
  enemy:SetPainSound("zombies-voice-sfx::A_Zombies_Hit_Cue")
  enemy:SetDeathSound("zombies-voice-sfx::A_Zombies_Death_Cue")
  enemy:PlayAnimation("nanos-world::A_Zombie_Chase_Loop", AnimationSlotType.UpperBody, true)

  -- Makes enemy follow the player
  if near_player_character then
    enemy:Follow(near_player_character, 10)
  end

  -- When enemy dies, drops a XP
  enemy:Subscribe("Death", function(self)
    -- TODO get amount of XP of this enemy
    SpawnXP(self:GetLocation(), 1)

    -- Destroy the Character after some seconds
    Timer.Bind(
      Timer.SetTimeout(function(chara)
        chara:Destroy()
      end, 2000, self),
      self
    )
  end)

  -- Create damage system?
  local fov = Trigger(Vector(0, 100, -100000), Rotator(), Vector(50 * enemy:GetScale().X, 50 * enemy:GetScale().Y, 400),
    TriggerType.Box, false, Color(0, 1, 0))
  fov:AttachTo(enemy, AttachmentRule.SnapToTarget, nil, 0)
  fov:SetRelativeLocation(Vector(50, 0, 0))
  fov:Subscribe("BeginOverlap", function(trigger, actor_triggering)
    if actor_triggering ~= nil and actor_triggering:GetType() == "Character" and actor_triggering:GetTeam() ~= 2 then
      enemy:PlayAnimation("nanos-world::AM_Mannequin_Melee_Slash_Attack", AnimationSlotType.FullBody, false, 0.25, 0.25,
        1, false)
      enemy:StopMovement()
      Timer.SetTimeout(function(_enemy)
        local hero = GetRandomHero()
        local damage = Trigger(Vector(0, 100, -100000), Rotator(),
          Vector(50 * enemy:GetScale().X, 50 * enemy:GetScale().Y, 400), TriggerType.Box, false, Color(1, 0, 0))
        damage:AttachTo(_enemy, AttachmentRule.SnapToTarget, nil, 0)
        damage:SetRelativeLocation(Vector(50, 0, 0))
        damage:Subscribe("BeginOverlap", function(trigger, actor_triggering)
          if actor_triggering:GetType() == "Character" and actor_triggering:GetTeam() ~= 2 then
            actor_triggering:ApplyDamage(10, nil, DamageType.Punch)
          end
        end)
        damage:SetLifeSpan(1)
        _enemy:Follow(hero, 10)
      end, 800, enemy)
    end
  end)
end

function SpawnXP(location, amount)
  -- Hardcodes Z location at 10
  location.Z = 10

  -- Spawns a XP Prop
  local prop = Prop(location, Rotator(), "nanos-world::SM_Cube", CollisionType.NoCollision, false, GrabMode.Disabled,
    CCDMode.Disabled)
  prop:SetScale(Vector(0.2, 0.2, 0.2))
  prop:SetMaterialColorParameter("Emissive", Color.GREEN * 5)

  -- Spawns a Trigger so Character can grab it when passing through
  local trigger = Trigger(location, Rotator(), Vector(XPPickUpRange), TriggerType.Sphere, false)

  -- When Character passes through, Grab the XP
  trigger:Subscribe("BeginOverlap", function(self, object)
    if (NanosUtils.IsA(object, Character)) then
      local player = object:GetPlayer()
      if (not player) then return end
      GrabXP(player, self)
    end
  end)

  -- When Prop is destroyed, consider it was grabbed by a Player
  prop:Subscribe("Destroy", function(self)
    -- TODO only in-game state
    UpdateXP(location, 1)
  end)

  -- can't attach because of bug dont translateto
  -- prop:AttachTo(trigger, AttachmentRule.SnapToTarget, "", 0)
  trigger:SetValue("Prop", prop)
end

function GrabXP(player, xp_trigger)
  local _prop = xp_trigger:GetValue("Prop")

  -- _prop:Detach()
  _prop:TranslateTo(player:GetControlledCharacter():GetLocation(), 0.1)
  _prop:SetLifeSpan(0.1)
  xp_trigger:Destroy()
end

function UpdateXP(location, amount)
  -- todo only in playing state
  Events.BroadcastRemote("SpawnSound", location, "nanos-world::A_Headshot_Feedback", false, 0.2, 2)

  NanoSurvivors.CurrentXP = NanoSurvivors.CurrentXP + amount
  print("xp up! " .. NanoSurvivors.CurrentXP)

  -- Level Up
  if (NanoSurvivors.CurrentXP >= NanoSurvivors.MaxXP) then
    NanoSurvivors.CurrentLevel = NanoSurvivors.CurrentLevel + 1
    NanoSurvivors.CurrentXP = 0
    NanoSurvivors.MaxXP = NanoSurvivors.MaxXP + 10

    Package.Log("Level up to %d! %d XP needed.", NanoSurvivors.CurrentLevel, NanoSurvivors.MaxXP)
    for _, player in pairs(Player.GetAll()) do
      local char = player:GetControlledCharacter()
      char:SetValue("NanoSurvivors.Level", NanoSurvivors.Level)
    end

    Events.BroadcastRemote("SpawnSound", location, "package///nano-survivors/Client/SFX/level_up.ogg", true, 1, 1)
    Events.BroadcastRemote("UpdateLevel", NanoSurvivors.CurrentLevel)
    Events.BroadcastRemote("LevelUpSkills", GetSetOfSkills())
  end

  -- Update players XP
  Events.BroadcastRemote("UpdateXP", NanoSurvivors.CurrentXP, NanoSurvivors.MaxXP)
end

Character.Subscribe("MoveCompleted", function(self, success)
  -- explode?
end)


Timer.SetInterval(function()
  if (not MainChar) then return end
  if #Character.GetAll() < 100 then
    SpawnEnemies()
  end
end, 2000)
