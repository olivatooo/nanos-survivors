Skills = {}
SkillID = 1
DEBUG = false

function RegisterSkill(skill_title, skill_description, skill_icon, skill_function)
  table.insert(Skills, {
    Title = skill_title,
    Description = skill_description,
    -- All functions must receive character as argument
    Function = skill_function,
    Icon = skill_icon,
    ID = SkillID
  })
  SkillID = SkillID + 1
  Package.Log("Registered Skill Title: " .. skill_title)
  if DEBUG then
    Package.Log("Registered Skill Description: " .. skill_description)
    Package.Log("Registered Skill Icon: " .. skill_icon)
    Package.Log(skill_function)
    Package.Log("")
  end
end

Events.Subscribe("RegisterSkill", RegisterSkill)

-- Base Skills

function AutoFire(character)
  local weapon = character:GetPicked()
  weapon:SetHandlingMode(HandlingMode.DoubleHandedWeapon)
  weapon:SetUsageSettings(true, false)
  -- Always reduce cadence
  local cadence = weapon:GetCadence()
  cadence = cadence * 0.8
  if cadence < 0.5 then
    weapon:SetSoundDry("nanos-world::A_Rifle_Dry")
    weapon:SetSoundLoad("nanos-world::A_Rifle_Load")
    weapon:SetSoundUnload("nanos-world::A_Rifle_Unload")
    weapon:SetSoundZooming("nanos-world::A_AimZoom")
    weapon:SetSoundAim("nanos-world::A_Rattle")
    weapon:SetSoundFire("nanos-world::A_AK47_Shot")
    weapon:SetAnimationFire("nanos-world::A_AK47_Fire")
    weapon:SetAnimationCharacterFire("nanos-world::AM_Mannequin_Sight_Fire")
    weapon:SetAnimationReload("nanos-world::AM_Mannequin_Reload_Rifle")
    weapon:SetMagazineMesh("nanos-world::SM_AK47_Mag_Empty")
  end
  weapon:SetCadence(cadence)
end

RegisterSkill("Auto Weapon", "Set your weapon to automatic fire and reduce cadence", "infinity", AutoFire)

function IncreaseDamage(character)
  local weapon = character:GetPicked()
  local damage = weapon:GetDamage()
  damage = damage + 10
  weapon:SetDamage(damage)
end

RegisterSkill("Damage+", "More damage! That's it", "knife-thrust", IncreaseDamage)

function MoreBullets(character)
  local weapon = character:GetPicked()
  local bullet_count = weapon:GetBulletCount()
  bullet_count = bullet_count + 3
  local spread = weapon:GetSpread()
  spread = spread + 10
  weapon:SetSpread(spread)
  weapon:SetBulletSettings(bullet_count, 20000, 20000, Color.Random())
end

RegisterSkill("Shotgunner", "Increase number of bullets, but reduce precision", "spiky-explosion", MoreBullets)

function IncreaseMagazine(character)
  local weapon = character:GetPicked()
  local clip_capacity = weapon:GetClipCapacity()
  clip_capacity = clip_capacity + 30
  weapon:SetClipCapacity(clip_capacity)
  weapon:SetAmmoClip(clip_capacity)
  weapon:SetAmmoSettings(clip_capacity, 10000000, clip_capacity, clip_capacity)
end

RegisterSkill("Bigger Magazine", "Increase magazine size by 30!", "ammo-box", IncreaseMagazine)

function SnowAura(character)
  local location = character:GetLocation()
  local snow_trigger_extent = character:GetValue("SnowAuraExtent") or 0
  snow_trigger_extent = snow_trigger_extent + 200
  character:SetValue("SnowAuraExtent", snow_trigger_extent)
  local snow_trigger = character:GetValue("SnowAura") or
      Trigger(location, Rotator(), snow_trigger_extent, TriggerType.Sphere, false, Color(0, 0, 1))
  snow_trigger:SetExtent(snow_trigger_extent)
  snow_trigger:AttachTo(character)
  snow_trigger:Subscribe("BeginOverlap", function(_, zombie)
    if zombie:IsA(Character) and zombie:GetHealth() > 0 and zombie:GetTeam() ~= 1 then
      zombie:ApplyDamage(1)
      zombie:SetSpeedMultiplier(0.3)
      zombie:SetMaterialColorParameter("Tint", Color(0, 0, 255))
    end
  end)
  character:SetValue("SnowAura", snow_trigger)
end

RegisterSkill("Snow Aura", "Create a snow aura or extend an existing one", "snowing", SnowAura)

function InfernoAura(character)
  local location = character:GetLocation()
  local inferno_trigger_extent = character:GetValue("InfernoAuraExtent") or 0
  inferno_trigger_extent = inferno_trigger_extent + 100
  character:SetValue("InfernoAuraExtent", inferno_trigger_extent)

  local inferno_damage = character:GetValue("InfernoDamage") or 0
  inferno_damage = inferno_damage + 1
  character:SetValue("InfernoDamage", inferno_damage)

  local inferno_trigger = character:GetValue("InfernoAura") or
      Trigger(location, Rotator(), inferno_trigger_extent, TriggerType.Sphere, false, Color(1, 0, 0))
  inferno_trigger:SetExtent(inferno_trigger_extent)
  inferno_trigger:AttachTo(character)
  inferno_trigger:Subscribe("BeginOverlap", function(_, zombie)
    if zombie:IsA(Character) and zombie:GetHealth() > 0 and zombie:GetTeam() ~= 1 then
      if next(zombie:GetAttachedEntities()) == nil then
        zombie:SetMaterialColorParameter("Tint", Color(255, 0, 0))
        local fire = Particle(
          zombie:GetLocation(),
          Rotator(0, 0, 0),
          "nanos-world::P_Fire",
          false, -- Auto Destroy?
          true   -- Auto Activate?
        )
        fire:SetLifeSpan(2)
        fire:AttachTo(zombie)
      end
      local inferno = Timer.SetInterval(function(_zombie, _character)
        _zombie:ApplyDamage(_character:GetValue("InfernoDamage"))
      end, 1000, zombie, character)

      Timer.Bind(inferno, zombie)
    end
  end)
  character:SetValue("InfernoAura", inferno_trigger)
end

RegisterSkill("Inferno Aura", "Create a inferno aura or extend an existing one", "celebration-fire", InfernoAura)

function IsAZombie(zombie)
  if zombie and zombie:IsValid() and zombie:IsA(Character) and zombie:GetHealth() > 0 and zombie:GetTeam() ~= 1 then
    return true
  end
  return false
end

function BallOfFire(character)
  local fire_damage = character:GetValue("FireDamage") or 0
  fire_damage = fire_damage + 2
  character:SetValue("FireDamage", fire_damage)
  local ball_of_fire = Timer.SetInterval(function(_character)
    Events.BroadcastRemote("SpawnSound", Vector(0), "package://nano-survivors/Client/SFX/fireball.ogg", true, 0.2, 1)
    local ball_effect = StaticMesh(
      _character:GetLocation(),
      Rotator(),
      "nanos-world::SM_Sphere"
    )
    ball_effect:SetScale(Vector(0.25))
    ball_effect:SetCollision(CollisionType.NoCollision)
    ball_effect:SetMaterial("nanos-world::M_Wireframe")
    ball_effect:SetMaterialColorParameter("Tint", Color(255, 0, 0))
    ball_effect:SetMaterialColorParameter("Emissive", Color(255, 0, 0))

    local ball_damage = Trigger(ball_effect:GetLocation(), Rotator(), Vector(50), TriggerType.Sphere, false,
      Color(1, 0, 0))
    ball_damage:Subscribe("BeginOverlap", function(_, zombie)
      if IsAZombie(zombie) then
        Events.BroadcastRemote("SpawnSound", Vector(0), "package://nano-survivors/Client/SFX/flesh_hit.ogg", true, 0.2,
          1.5)
        zombie:ApplyDamage(character:GetValue("FireDamage"))
        Particle(
          zombie:GetLocation(),
          Rotator(0, 0, 0),
          "nanos-world::P_Explosion",
          true, -- Auto Destroy?
          true  -- Auto Activate?
        )
      end
    end)
    ball_damage:AttachTo(ball_effect)
    ball_effect:TranslateTo(Vector(math.random(-10, 10) * 2500, math.random(-10, 10) * 2500, 10), 15)
    Timer.SetTimeout(function(_ball_damage, _ball_effect)
      _ball_damage:Destroy()
      _ball_effect:Destroy()
    end, 10000, ball_damage, ball_effect)
  end, 200, character)
  Timer.Bind(ball_of_fire, character)
end

RegisterSkill("Fire Wand", "Randomly shoots a ball of fire, or increase the number of balls, this pierces enemies",
  "burning-meteor", BallOfFire)

function BallOfIce(character)
  local ball_of_fire = Timer.SetInterval(function(_character)
    Events.BroadcastRemote("SpawnSound", Vector(0), "package://nano-survivors/Client/SFX/fireball.ogg", true, 0.2, 1)
    local ball_effect = StaticMesh(
      _character:GetLocation(),
      Rotator(),
      "nanos-world::SM_Sphere"
    )
    ball_effect:SetScale(Vector(0.8))
    ball_effect:SetCollision(CollisionType.NoCollision)
    ball_effect:SetMaterial("nanos-world::M_Wireframe")
    ball_effect:SetMaterialColorParameter("Tint", Color(0, 0, 255))
    ball_effect:SetMaterialColorParameter("Emissive", Color(0, 0, 255))

    local ball_damage = Trigger(ball_effect:GetLocation(), Rotator(), Vector(100), TriggerType.Sphere, false,
      Color(1, 0, 0))
    ball_damage:Subscribe("BeginOverlap", function(_, zombie)
      if IsAZombie(zombie) then
        Events.BroadcastRemote("SpawnSound", Vector(0), "package://nano-survivors/Client/SFX/flesh_hit.ogg", true, 0.2, 2)
        zombie:SetSpeedMultiplier(0.5)
        zombie:ApplyDamage(1)
      end
    end)
    ball_damage:AttachTo(ball_effect)
    ball_effect:TranslateTo(Vector(math.random(-10, 10) * 2500, math.random(-10, 10) * 2500, 10), 15)
    Timer.SetTimeout(function(_ball_damage, _ball_effect)
      _ball_damage:Destroy()
      _ball_effect:Destroy()
    end, 30000, ball_damage, ball_effect)
  end, 2000, character)
  Timer.Bind(ball_of_fire, character)
end

RegisterSkill("Ice Wand", "Randomly shoots a ball of ice, or increase the number of balls. This slow down enemies",
  "wind-hole", BallOfIce)

function LightningArc(character)
  local zap_value = character:GetValue("Lightning") or 0
  zap_value = zap_value + 10
  character:SetValue("Lightning", zap_value)
  local zap = Timer.SetInterval(function(_character)
    local zombie = Character.GetAll()[math.random(#Character.GetAll())]
    if IsAZombie(zombie) then
      Events.BroadcastRemote("SpawnSound", Vector(0), "package://nano-survivors/Client/SFX/zap.ogg", true, 0.2, 1)
      local beam_particle = Particle(Vector(), Rotator(), "nanos-world::P_Beam", false, true)
      beam_particle:AttachTo(_character, AttachmentRule.SnapToTarget, "muzzle")
      beam_particle:SetParameterColor("BeamColor", Color(0, 0, 10000, 1))
      beam_particle:SetParameterFloat("BeamWidth", 1.5)
      beam_particle:SetParameterFloat("JitterAmount", 1)
      beam_particle:SetParameterVector("BeamEnd", zombie:GetLocation())
      zombie:ApplyDamage(character:GetValue("Lightning"))
      beam_particle:SetLifeSpan(0.5)
    end
  end, 1000, character)
  Timer.Bind(zap, character)
end

RegisterSkill("Lightning Arc", "Zap Random Enemies! Create more arcs and increase arc damage", "lightning-arc",
  LightningArc)

function AerialSupport(character)
  Package.Log(character)
  local choppa = Timer.SetInterval(function(_character)
    local heli = Character(Vector(math.random(-1000, 3000), math.random(-1000, 3000), 5000), Rotator(0, 0, 0),
      "nanos-world::SK_Mannequin")
    heli:SetTeam(1)
    heli:SetWeaponAimMode(AimMode.ZoomedZoom)
    heli:SetFlyingMode(true)
    heli:SetLifeSpan(9)
    local wep = NanosWorldWeapons.P90()
    wep:SetSpread(500)
    wep:SetRecoil(500)
    wep:SetLifeSpan(9)
    wep:SetAmmoSettings(1000, 1000)
    heli:PickUp(wep)
    local aim_mode = Timer.SetInterval(function(_heli, _wep)
      local zombie = Character.GetAll()[math.random(#Character.GetAll())]
      if IsAZombie(zombie) then
        _heli:LookAt(zombie:GetLocation())
        _wep:PullUse()
      end
    end, 100, heli, wep)
    Timer.Bind(aim_mode, heli)
  end, 30000, character)
  Timer.Bind(choppa, character)
end

RegisterSkill("Aerial Support", "Every 30s get the help of the attack helicopter, increase the amount of helicopters",
  "hawk-emblem", AerialSupport)

function EnergyBall(character)
  local energy_damage = character:GetValue("EnergyBall") or 0
  energy_damage = energy_damage + 4
  character:SetValue("ExplosionDamage", energy_damage)
  Timer.SetInterval(function(_character)
    Events.BroadcastRemote("SpawnSound", Vector(0), "package://nano-survivors/Client/SFX/fireball.ogg", true, 0.2, 0.5)
    local zombie = Character.GetAll()[math.random(#Character.GetAll())]
    if IsAZombie(zombie) then
      local energy_ball = StaticMesh(_character:GetLocation() + Vector(0, 0, 15000), Rotator(), "nanos-world::SM_Sphere")
      energy_ball:SetCollision(CollisionType.NoCollision)
      energy_ball:TranslateTo(zombie:GetLocation() + Vector(math.random(200), math.random(200), 800), 1, 0.2)
      energy_ball:SetMaterial("nanos-world::M_NanosTranslucent")
      energy_ball:SetMaterialScalarParameter("Metallic", 0.5)
      energy_ball:SetMaterialScalarParameter("Opacity", 0.1)
      energy_ball:SetMaterialColorParameter("Emissive", Color(10000, 0, 0))
      energy_ball:SetMaterialColorParameter("Tint", Color(1000, 0, 0))
      local trigger = Trigger(Vector(), Rotator(), Vector(50), TriggerType.Sphere, false, Color(1, 0, 0))
      trigger:AttachTo(energy_ball, AttachmentRule.SnapToTarget)
      Timer.SetTimeout(function(_energy_ball, _zombie_location)
        _energy_ball:TranslateTo(_zombie_location, 1, 0.2)
      end, 4000, energy_ball, zombie:GetLocation())
      Timer.SetTimeout(function(aim, __character)
        local explosion = Grenade(aim:GetLocation(), Rotator(0, 90, 90), "nanos-world::SM_Grenade_G67",
          "nanos-world::P_Explosion_Water", "nanos-world::A_Explosion_Large")
        explosion:SetDamage(__character:GetValue("ExplosionDamage"))
        aim:GetAttachedEntities()[1]:Destroy()
        explosion:Explode()
        aim:Destroy()
      end, 6000, energy_ball, _character)
    end
  end, 2000, character)
end

RegisterSkill("Energy Ball", "Every 2s spawn a explosive ball of energy and upgrades explosion damage", "ball-glow",
  EnergyBall)

function GetLookAt(tPos, fPos)
  return (tPos - fPos):Rotation()
end

function AutoAim(character)
  local auto_aim = character:GetValue("AutoAim")
  local player = character:GetPlayer()
  Events.CallRemote("AutoAim", player)
  if auto_aim == true then
    IncreaseMagazine(character)
  else
    character:SetValue("AutoAim", true)
    local aim_mode = Timer.SetInterval(function(_aim_bot)
      local zombie = Character.GetAll()[#Character.GetAll()]
      if IsAZombie(zombie) then
        -- _aim_bot:LookAt(zombie:GetLocation())
        _aim_bot:SetRotation(GetLookAt(zombie:GetLocation(), _aim_bot:GetLocation()))
        local wep = _aim_bot:GetPicked()
        wep:PullUse()
      end
    end, 200, character)
    Timer.Bind(aim_mode, character)
  end
end

RegisterSkill("Aim Bot",
  "Auto Aim and Fire your weapon at RANDOM enemies! If you are already auto aiming you get increased magazine size. CAUTION YOU WILL NOT BE ABLE TO AIM AFTER THIS",
  "frontal-lobe", AutoAim)

function XPMagnet()
  XPPickUpRange = XPPickUpRange + 200
end

RegisterSkill("XP Magnet", "Increase XP pickup range by 1m", "holosphere", XPMagnet)

function BallOfCoal(character)
  local coal_damage = character:GetValue("CoalDamage") or 0
  coal_damage = coal_damage + 10
  character:SetValue("CoalDamage", coal_damage)
  local ball_of_fire = Timer.SetInterval(function(_character)
    Events.BroadcastRemote("SpawnSound", Vector(0), "package://nano-survivors/Client/SFX/fireball.ogg", true, 0.2, 0.8)
    local ball_effect = StaticMesh(
      _character:GetLocation(),
      Rotator(),
      "nanos-world::SM_Sphere"
    )
    ball_effect:SetScale(Vector(0.25))
    ball_effect:SetCollision(CollisionType.NoCollision)
    ball_effect:SetMaterialColorParameter("Tint", Color(0, 0, 0))
    ball_effect:TranslateTo(Vector(math.random(-10, 10) * 2500, math.random(-10, 10) * 2500, 10), 15)
    local ball_damage = Trigger(ball_effect:GetLocation(), Rotator(), Vector(50), TriggerType.Sphere, false,
      Color(1, 0, 0))
    ball_damage:AttachTo(ball_effect)
    ball_damage:Subscribe("BeginOverlap", function(s, zombie)
      if IsAZombie(zombie) then
        zombie:ApplyDamage(_character:GetValue("CoalDamage"))
        Particle(
          zombie:GetLocation(),
          Rotator(0, 0, 0),
          "nanos-world::P_Explosion",
          true, -- Auto Destroy?
          true  -- Auto Activate?
        )
        Events.BroadcastRemote("SpawnSound", Vector(0), "package://nano-survivors/Client/SFX/flesh_hit.ogg", true, 0.2, 1)
        s:Destroy()
        ball_effect:Destroy()
      end
    end)
  end, 1000, character)
  Timer.Bind(ball_of_fire, character)
end

RegisterSkill("Charged Arrow", "Randomly shoots a STRONG projectile, this does not pierces enemies", "charged-arrow",
  BallOfCoal)


function HydraShot(character)
  local wep = character:GetPicked()
  wep:Subscribe("Fire", function(self, shooter)
    if math.random(100) > 90 then
      Events.BroadcastRemote("SpawnSound", Vector(0), "package://nano-survivors/Client/SFX/strong_hit.ogg", true, 0.5, 1)
      local coin = Prop(
        character:GetLocation(),
        Rotator(),
        "nanos-world::SM_Sphere",
        CollisionType.Normal,
        true,
        GrabMode.Disabled,
        CCDMode.Disabled
      )
      coin:SetLifeSpan(5)
      coin:SetScale(Vector(0.1, 0.1, 0.1))
      coin:SetMaterial("nanos-world::M_Wireframe")
      coin:SetMaterialColorParameter("Tint", Color(255, 164, 0))
      coin:SetMaterialColorParameter("Emissive", Color(255, 164, 0))
      local trail_particle = Particle(coin:GetLocation(), Rotator(), "nanos-world::P_Ribbon", false, true)
      trail_particle:SetParameterColor("Color", Color(255, 164, 0))
      trail_particle:SetParameterFloat("LifeTime", 1)
      trail_particle:SetParameterFloat("SpawnRate", 30)
      trail_particle:SetParameterFloat("Width", 0.01)
      trail_particle:AttachTo(coin)
      coin:SetValue("Particle", trail_particle)
      local range_of_effect = Trigger(character:GetLocation(), Rotator(), Vector(1000), TriggerType.Sphere, false,
        Color(1, 0, 0))
      range_of_effect:Subscribe("BeginOverlap", function(_, actor_triggering)
        -- Found possible target
        if IsAZombie(actor_triggering) then
          coin:TranslateTo(actor_triggering:GetLocation(), 0.1, 2)
          actor_triggering:ApplyDamage(self:GetDamage())
        end
      end)
      range_of_effect:SetLifeSpan(1)
    end
  end)
end

RegisterSkill("Hydra Shot", "Bullets have a 10 percent of chance to split to nearby enemies", "hydra-shot", HydraShot)

function SixthTheLuck(character)
  local wep = character:GetPicked()
  local critical_amount = wep:GetValue("SixthTheLuck_Critical") or 1
  critical_amount = critical_amount * 2
  wep:SetValue("SixthTheLuck_Critical", critical_amount)
  wep:Subscribe("Fire", function(weapon, shooter)
    local six = weapon:GetValue("SixthTheLuck_Count") or 1
    local ca = wep:GetValue("SixthTheLuck_Critical") or 1
    if six == 6 then
      weapon:SetValue("OriginalDamage", weapon:GetDamage())
      Events.BroadcastRemote("SpawnSound", Vector(0), "package://nano-survivors/Client/SFX/hit_distance.ogg", true, 0.8,
        1)
      wep:SetDamage(ca * wep:GetDamage())
    end
    if six == 7 then
      local od = weapon:GetValue("OriginalDamage")
      weapon:SetDamage(od)
      six = 1
    end
    six = six + 1
  end)
end

RegisterSkill("Lucky Six", "Critical every sixth shot! If you already have this, increase critical by 2x", "chaingun",
  SixthTheLuck)

function DigitalShockwave(character)
  local digital_shockwave = character:GetValue("DigitalShockwave") or 0
  digital_shockwave = digital_shockwave + 1
  character:SetValue("DigitalShockwave", digital_shockwave)
  local radius = 100
  -- If it's the first iteration then create the power up effect, else just increase it's damage
  local shock = Timer.SetInterval(function(_character, _radius)
    local wave = Trigger(_character:GetLocation(), Rotator(), Vector(_radius), TriggerType.Sphere, false, Color(1, 0, 0))
    wave:Subscribe("BeginOverlap", function(_, zombie)
      if IsAZombie(zombie) then
        zombie:ApplyDamage(character:GetValue("DigitalShockwave"))
        Events.BroadcastRemote("SpawnSound", Vector(0), "package://nano-survivors/Client/SFX/digital.ogg", true, 0.3, 1)
      end
    end)
    digital = StaticMesh(
      wave:GetLocation(),
      Rotator(),
      "nanos-world::SM_Sphere"
    )
    digital:SetCollision(CollisionType.NoCollision)
    digital:SetMaterial("nanos-world::M_Wireframe")
    digital:SetMaterialColorParameter("Tint", Color(0, 255, 0))
    digital:SetMaterialColorParameter("Emissive", Color(0, 255, 0))
    digital:SetScale(Vector(_radius / 50))
    local bigger = Timer.SetInterval(function(_wave, _digital)
      _wave:SetExtent(Vector(_radius))
      _radius = _radius + 10
      _digital:SetScale(Vector(_radius / 50))
      if _radius > 1000 then
        _wave:Destroy()
        _digital:Destroy()
      end
    end, 5, wave, digital)
    Timer.Bind(bigger, digital)
  end, 10000, character, radius)
  Timer.Bind(shock, character)
end

RegisterSkill("Digital Shockwave",
  "Every 10s send a shockwave that affects all zombies in the range, this increases shockwave damage and range",
  "mesh-ball", DigitalShockwave)

function FlameTunnel(character)
  local flame_tunnel_damage = character:GetValue("FlameTunnel") or 0
  flame_tunnel_damage = flame_tunnel_damage + 2
  character:SetValue("FlameTunnel", flame_tunnel_damage)
  local flame_damage = Timer.SetInterval(function(_character)
    local flame_tunnel = Trigger(_character:GetLocation(), Rotator(), 100, TriggerType.Sphere, false, Color(1, 0, 0))
    flame_tunnel:Subscribe("BeginOverlap", function(_, zombie)
      if IsAZombie(zombie) then
        Events.BroadcastRemote("SpawnSound", Vector(0), "package://nano-survivors/Client/SFX/flesh_hit.ogg", true, 0.2, 1)
        if next(zombie:GetAttachedEntities()) == nil then
          zombie:ApplyDamage(character:GetValue("FlameTunnel"))
          zombie:SetMaterialColorParameter("Tint", Color(255, 0, 0))
          local fire = Particle(
            zombie:GetLocation(),
            Rotator(0, 0, 0),
            "nanos-world::P_Fire",
            false, -- Auto Destroy?
            true   -- Auto Activate?
          )
          fire:SetLifeSpan(2)
          fire:AttachTo(zombie)
        end
      end
    end)
    local napalm_fire = Particle(
      _character:GetLocation() - Vector(0, 0, 97),
      Rotator(0, 0, 0),
      "nanos-world::P_Fire_01",
      false,
      true
    )
    napalm_fire:SetLifeSpan(2)
    flame_tunnel:SetLifeSpan(2)
  end, 500, character)
  Timer.Bind(flame_damage, character)
end

RegisterSkill("Flame Path", "Spread fire when you walk, increases fire damage", "flame-tunnel", FlameTunnel)

function BreathOfFire(character)
  local flame_tunnel_damage = character:GetValue("FlameTunnel") or 0
  flame_tunnel_damage = flame_tunnel_damage + 2
  character:SetValue("FlameTunnel", flame_tunnel_damage)
  local flame_damage = Timer.SetInterval(function(_character)
    local flame_tunnel = Trigger(_character:GetLocation(), Rotator(), 100, TriggerType.Sphere, false, Color(1, 0, 0))
    Events.BroadcastRemote("SpawnSound", Vector(0), "package://nano-survivors/Client/SFX/fire_breath.ogg", true, 0.2, 1)
    flame_tunnel:Subscribe("BeginOverlap", function(_, zombie)
      if IsAZombie(zombie) then
        Events.BroadcastRemote("SpawnSound", Vector(0), "package://nano-survivors/Client/SFX/flesh_hit.ogg", true, 0.2, 1)
        if next(zombie:GetAttachedEntities()) == nil then
          zombie:ApplyDamage(character:GetValue("FlameTunnel"))
          zombie:SetMaterialColorParameter("Tint", Color(255, 0, 0))
          local fire = Particle(
            zombie:GetLocation(),
            Rotator(0, 0, 0),
            "nanos-world::P_Fire_02",
            false, -- Auto Destroy?
            true   -- Auto Activate?
          )
          fire:SetLifeSpan(2)
          fire:AttachTo(zombie)
        end
      end
    end)
    local napalm_fire = Particle(
      _character:GetLocation() - Vector(0, 0, 97),
      Rotator(0, 0, 0),
      "nanos-world::P_Fire_01",
      false,
      true
    )
    napalm_fire:SetScale(Vector(3))
    napalm_fire:SetLifeSpan(4)
    flame_tunnel:SetLifeSpan(4)
  end, 4000, character)
  Timer.Bind(flame_damage, character)
end

RegisterSkill("Breath Of Fire", "Every 4 seconds spits fire in front of the character, increases fire damage",
  "fire-breath", BreathOfFire)

function Imprison(character)
  local damage = character:GetValue("Imprison") or 0
  damage = damage + 2
  character:SetValue("Imprison", damage)
  Timer.SetInterval(function(_character)
    local vicinity = _character:GetLocation() + Vector(math.random(-500, 500), math.random(-500, 500), 100)
    local trigger = Trigger(vicinity, Rotator(), 400, TriggerType.Sphere, false, Color(0, 0, 1))
    trigger:Subscribe("BeginOverlap", function(_, zombie)
      if IsAZombie(zombie) then
        zombie:ApplyDamage(character:GetValue("Imprison"))
        local stop = StaticMesh(zombie:GetLocation() - Vector(0, 0, -100), Rotator(),
          "nanos-world::SM_StreetSigns_NoEntry", CollisionType.NoCollision)
        stop:SetLifeSpan(2)
        zombie:SetSpeedMultiplier(0.01)
        local z = Timer.SetTimeout(function(_zombie)
          _zombie:SetSpeedMultiplier(1)
        end, 2000, zombie)
        Timer.Bind(z, zombie)
      end
    end)
    trigger:SetLifeSpan(3)
  end, 3000, character)
end

RegisterSkill("Stop! Hammer Time", "Every 3 seconds stuns and hits random enemies in vicinity", "imprisoned", Imprison)

function WillOWisp(character)
  local damage = character:GetValue("WillOWisp") or 0
  damage = damage + 1
  character:SetValue("WillOWisp", damage)
  Character.Subscribe("Death", function(self, _, _, _, _, _, _)
    local explosion = Grenade(self:GetLocation() + Vector(100), Rotator(0, 90, 90), "nanos-world::SM_Grenade_G67",
      "nanos-world::P_Explosion", "nanos-world::A_Explosion_Large")
    explosion:SetDamage(character:GetValue("WillOWisp"))
    explosion:Explode()
  end)
end

RegisterSkill("Will-o-Wisp", "Enemies explode on death, increases explosion damage", "internal-injury", WillOWisp)


function TeslaCoil(character)
  local damage = character:GetValue("Tesla") or 1
  damage = damage + 2
  character:SetValue("Tesla", damage)
  local location = character:GetLocation()
  local tesla_coil = StaticMesh(
    location,
    Rotator(),
    "nanos-world::SM_Torus"
  )
  tesla_coil:SetMaterialColorParameter("Tint", Color(0, 0, 255))
  tesla_coil:SetCollision(CollisionType.NoCollision)
  local trigger = Trigger(location, Rotator(), 300, TriggerType.Sphere, false, Color(0, 0, 1))
  trigger:Subscribe("BeginOverlap", function(_, zombie)
    if IsAZombie(zombie) then
      local zap = Timer.SetInterval(function()
        Events.BroadcastRemote("SpawnSound", Vector(0), "package://nano-survivors/Client/SFX/zap.ogg", true, 0.5, 1.6)
        local beam_particle = Particle(Vector(), Rotator(), "nanos-world::P_Beam", false, true)
        beam_particle:AttachTo(tesla_coil, AttachmentRule.SnapToTarget, "muzzle")
        beam_particle:SetParameterColor("BeamColor", Color(0, 0, 10000, 1))
        beam_particle:SetParameterFloat("BeamWidth", 1.5)
        beam_particle:SetParameterFloat("JitterAmount", 10)
        beam_particle:SetParameterVector("BeamEnd", zombie:GetLocation())
        zombie:ApplyDamage(character:GetValue("Tesla"))
        beam_particle:SetLifeSpan(0.5)
      end, 350)
      Timer.Bind(zap, zombie)
    end
  end)
end

RegisterSkill("Tesla Coil",
  "Spawns a permanent tesla coil that deals damage on vicinity, this upgrades all other existing tesla coils",
  "lightning-spanner", TeslaCoil)

function RingOfFire(character)
  local damage = character:GetValue("FireTower") or 1
  damage = damage + 4
  character:SetValue("FireTower", damage)
  local location = character:GetLocation()
  local tesla_coil = StaticMesh(
    location,
    Rotator(),
    "nanos-world::SM_Torus"
  )
  local fire = Particle(
    tesla_coil:GetLocation(),
    Rotator(0, 0, 0),
    "nanos-world::P_Fire",
    false, -- Auto Destroy?
    true   -- Auto Activate?
  )
  fire:SetScale(Vector(4))
  fire:AttachTo(tesla_coil)
  tesla_coil:SetMaterialColorParameter("Tint", Color(255, 0, 0))
  tesla_coil:SetCollision(CollisionType.NoCollision)
  local trigger = Trigger(location, Rotator(), 200, TriggerType.Sphere, false, Color(0, 0, 1))
  trigger:Subscribe("BeginOverlap", function(_, zombie)
    if IsAZombie(zombie) then
      Events.BroadcastRemote("SpawnSound", Vector(0), "package://nano-survivors/Client/SFX/fire_breath.ogg", true, 0.8,
        1.6)
      zombie:ApplyDamage(character:GetValue("FireTower"))
    end
  end)
end

RegisterSkill("Ring Of Fire",
  "Spawns a permanent tower that deals fire damage on vicinity, this upgrades all other existing fire towers",
  "burning-embers", RingOfFire)


function Duality()
  Character.Subscribe("TakeDamage", function(char, damage, bone, dtype, from_direction, instigator, causer)
    if dtype ~= 7 then
      char:ApplyDamage(math.ceil(damage * 0.1), nil, 7)
    end
  end)
end

RegisterSkill("Duality", "Increase strong ALL strong damage by 10 per cent", "duality-mask", Duality)

function TheWorld(character)
  local number_of_knives = character:GetValue("TheWorld") or 0
  number_of_knives = number_of_knives + 6
  character:SetValue("TheWorld", number_of_knives)
  local world = Timer.SetInterval(function(_character)
    local spawn = character:GetValue("TheWorld")
    local spawn_of_hell = Timer.SetInterval(function(__character)
      local zombie = Character.GetAll()[math.random(#Character.GetAll())]
      if IsAZombie(zombie) then
        spawn = spawn - 1
        local m9 = StaticMesh(
          __character:GetLocation(),
          Rotator(),
          "nanos-world::SM_M9"
        )
        m9:SetCollision(CollisionType.NoCollision)
        m9:TranslateTo(__character:GetLocation() + Vector(0, 0, 100), 0.6, 1)
        m9:TranslateTo(zombie:GetLocation(), 0.3, 2)
        m9:SetLifeSpan(1)
        Timer.SetTimeout(function(_zombie)
          Events.BroadcastRemote("SpawnSound", Vector(0), "package://nano-survivors/Client/SFX/hit_distance.ogg", true,
            0.8, 1)
          local omniburst = Particle(
            _zombie:GetLocation(),
            Rotator(0, 0, 0),
            "nanos-world::P_OmnidirectionalBurst",
            true, -- Auto Destroy?
            true  -- Auto Activate?
          )
          _zombie:ApplyDamage(character:GetValue("TheWorld"))
          omniburst:SetParameterColor("Color", Color(255, 0, 0))
        end, 900, zombie)
        if spawn <= 0 then
          return false
        end
      end
    end, 200, _character)
    Timer.Bind(spawn_of_hell, _character)
  end, 6000, character)
  Timer.Bind(world, character)
end

RegisterSkill("The World", "Spawn knives to hit enemies", "kitchen-knives", TheWorld)

-- TODO: Create better algorithm
function GetSetOfSkills()
  local set_of_skills = {}

  local skill_1 = {}
  local s = Skills[math.random(#Skills)]
  for key, value in pairs(s) do
    if type(value) ~= "function" then
      skill_1[key] = value
    end
  end

  local skill_2 = {}
  s = Skills[math.random(#Skills)]
  for key, value in pairs(s) do
    if type(value) ~= "function" then
      skill_2[key] = value
    end
  end

  local skill_3 = {}
  s = Skills[math.random(#Skills)]
  for key, value in pairs(s) do
    if type(value) ~= "function" then
      skill_3[key] = value
    end
  end

  set_of_skills[1] = skill_1
  set_of_skills[2] = skill_2
  set_of_skills[3] = skill_3
  Package.Log(set_of_skills[1])
  Package.Log(set_of_skills)
  Package.Log(JSON.stringify(set_of_skills))
  return set_of_skills
  -- return JSON.stringify(set_of_skills)
end

function UpgradeSkill(player, id)
  local character = player:GetControlledCharacter()
  Skills[id].Function(character)
end

Events.Subscribe("UpgradeSkill", UpgradeSkill)
