global function OnWeaponPrimaryAttack_gun_shield
global function MpTitanAbilityGunShield_Init

#if SERVER
global function OnWeaponNpcPrimaryAttack_gun_shield
#else
global function ServerCallback_PilotCreatedGunShield
#endif

const FX_TITAN_GUN_SHIELD_VM = $"P_titan_gun_shield_FP"
const FX_TITAN_GUN_SHIELD_WALL = $"P_titan_gun_shield_3P"
const FX_TITAN_GUN_SHIELD_WALL_PILOT = $"P_anti_titan_shield_3P"
const FX_TITAN_GUN_SHIELD_BREAK = $"P_xo_armor_break_CP"
global const float TITAN_GUN_SHIELD_RADIUS = 105
global const int TITAN_GUN_SHIELD_HEALTH = 2500
global const int PAS_LEGION_SHEILD_HEALTH = 5000

// pilot gunshields
const int PILOT_GUN_SHIELD_RADIUS = 35
const int PILOT_GUN_SHIELD_HEIGHT = 60
const int PILOT_GUN_SHIELD_FOV = 75
const int PILOT_GUN_SHIELD_HEALTH = 200

#if CLIENT
struct
{
	int sphereClientFXHandle = -1
} file
#endif

void function MpTitanAbilityGunShield_Init()
{
	PrecacheParticleSystem( FX_TITAN_GUN_SHIELD_WALL )
	PrecacheParticleSystem( FX_TITAN_GUN_SHIELD_VM )
	PrecacheParticleSystem( FX_TITAN_GUN_SHIELD_BREAK )
	PrecacheParticleSystem( FX_TITAN_GUN_SHIELD_WALL_PILOT )
	RegisterSignal( "GunShieldEnd" )
}

var function OnWeaponPrimaryAttack_gun_shield( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	entity weaponOwner = weapon.GetWeaponOwner()

	Assert( IsValid( weaponOwner ), "weapon owner is not valid at the start of on weapon primary attack" )
	Assert( IsAlive( weaponOwner ), "weapon owner is not alive at the start of on weapon primary attack" )
	array<entity> weapons = GetPrimaryWeapons( weaponOwner )
	Assert( weapons.len() > 0 )
	if ( weapons.len() == 0 )
		return 0

	entity primaryWeapon = weapons[0]
	if ( !IsValid( primaryWeapon ) )
		return 0

	if ( weaponOwner.ContextAction_IsActive() )
		return 0

	float duration = weapon.GetWeaponSettingFloat( eWeaponVar.fire_duration )
	if ( weaponOwner.IsPlayer() )
		PlayerUsedOffhand( weaponOwner, weapon )
	if( IsPilot( weaponOwner ) )
	{
		#if SERVER
		thread CreateHumanSizedGunShield( weaponOwner, duration )
		#endif
	}
	else
		thread GunShieldThink( primaryWeapon, weapon, weaponOwner, duration )
	return weapon.GetWeaponSettingInt( eWeaponVar.ammo_per_shot )
}

void function GunShieldThink( entity weapon, entity shieldWeapon, entity owner, float duration )
{
	weapon.EndSignal( "OnDestroy" )
	owner.EndSignal( "OnDestroy" )
	owner.EndSignal( "OnDeath" )
	owner.EndSignal( "DisembarkingTitan" )
	owner.EndSignal( "TitanEjectionStarted" )
	owner.EndSignal( "SettingsChanged")

	weapon.e.gunShieldActive = true
	weapon.SetForcedADS()
	if ( owner.IsPlayer() )
		owner.SetMeleeDisabled()

	OnThreadEnd(
	function() : ( weapon, owner )
		{
			if ( IsValid( weapon ) )
			{
				weapon.e.gunShieldActive = false
				if ( !weapon.HasMod( "LongRangePowerShot" ) && !weapon.HasMod( "CloseRangePowerShot" ) && !weapon.HasMod( "SiegeMode" ) )
				{
					while( weapon.GetForcedADS() )
						weapon.ClearForcedADS()
				}
				if( !IsPilot( owner ) )
					weapon.StopWeaponEffect( FX_TITAN_GUN_SHIELD_VM, FX_TITAN_GUN_SHIELD_WALL )
			}
			if ( IsValid( owner ) )
			{
				if ( owner.IsPlayer() )
					owner.ClearMeleeDisabled()
				owner.Signal( "GunShieldEnd" )
			}
		}
	)

	while( !weapon.IsReloading() && !CanUseGunShield( owner, true ) )
	{
		wait 0.1
	}

	#if SERVER
		thread Sv_CreateGunShield( owner, weapon, shieldWeapon, duration )
	#endif

	if ( duration > 0 )
		wait duration
	else
		WaitForever()
}

bool function CanUseGunShield( entity owner, bool reqZoom = true )
{
	if ( !owner.IsNPC() )
	{
		if ( !IsPilot( owner ) && owner.GetViewModelEntity().GetModelName() != $"models/weapons/titan_predator/atpov_titan_predator.mdl" )
			return false

		if ( owner.PlayerMelee_IsAttackActive() )
			return false
	}
	else
	{
		return owner.GetActiveWeapon().GetWeaponClassName() == "mp_titanweapon_predator_cannon"
	}

	return true
}

#if SERVER
var function OnWeaponNpcPrimaryAttack_gun_shield( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	OnWeaponPrimaryAttack_gun_shield( weapon, attackParams )
}
#endif

#if SERVER
void function Sv_CreateGunShield( entity titan, entity weapon, entity shieldWeapon, float duration )
{
	titan.EndSignal( "OnDeath" )
	titan.EndSignal( "OnDestroy" )
	titan.EndSignal( "DisembarkingTitan" )
	titan.EndSignal( "TitanEjectionStarted" )
	titan.EndSignal( "ContextAction_SetBusy" )

	entity vortexWeapon = weapon
	entity vortexSphere = CreateGunShieldVortexSphere( titan, vortexWeapon, shieldWeapon )
	int weaponEHandle = vortexWeapon.GetEncodedEHandle()
	int shieldEHandle = vortexSphere.GetEncodedEHandle()
	entity shieldWallFX = vortexSphere.e.shieldWallFX

	vortexSphere.EndSignal( "OnDestroy" )

	if ( titan.IsPlayer() )
	{
		if( !IsPilot( titan ) )
			Remote_CallFunction_Replay( titan, "ServerCallback_PilotCreatedGunShield", weaponEHandle, shieldEHandle )
		EmitSoundOnEntityOnlyToPlayer( vortexWeapon, titan, "weapon_predator_mountedshield_start_1p" )
		EmitSoundOnEntityExceptToPlayer( vortexWeapon, titan, "weapon_predator_mountedshield_start_3p" )
	}
	else
	{
		EmitSoundOnEntity( vortexWeapon, "weapon_predator_mountedshield_start_3p" )
	}

	OnThreadEnd(
		function() : ( titan, vortexSphere, vortexWeapon, shieldWallFX )
		{
			if ( IsValid( vortexWeapon ) )
			{
				StopSoundOnEntity( vortexWeapon, "weapon_predator_mountedshield_start_1p" )
				StopSoundOnEntity( vortexWeapon, "weapon_predator_mountedshield_start_3p" )
				if ( IsValid( titan ) && titan.IsPlayer() )
				{
					EmitSoundOnEntityOnlyToPlayer( vortexWeapon, titan, "weapon_predator_mountedshield_stop_1p" )
					EmitSoundOnEntityExceptToPlayer( vortexWeapon, titan, "weapon_predator_mountedshield_stop_3p" )
				}
				else
				{
					EmitSoundOnEntity( vortexWeapon, "weapon_predator_mountedshield_stop_3p" )
				}
				vortexWeapon.SetWeaponUtilityEntity( null )
			}

			if ( IsValid( shieldWallFX ) )
				EffectStop( shieldWallFX )

			if ( IsValid( vortexSphere ) )
			{
				vortexSphere.Destroy()
			}
			else if ( IsValid( titan ) )
			{
				EmitSoundOnEntity( titan, "titan_energyshield_down" )
				PlayFXOnEntity( FX_TITAN_GUN_SHIELD_BREAK, titan, "PROPGUN" )
			}
		}
	)

	if ( duration > 0 )
		wait duration
	else
		WaitForever()
}

void function CreateHumanSizedGunShield( entity player, float duration = 6.0 )
{
	vector angles = VectorToAngles( player.EyeAngles() )
	entity vortexSphere = CreateShieldWithSettings( player.GetOrigin(), angles, PILOT_GUN_SHIELD_RADIUS, PILOT_GUN_SHIELD_HEIGHT, PILOT_GUN_SHIELD_FOV, duration, PILOT_GUN_SHIELD_HEALTH, FX_TITAN_GUN_SHIELD_WALL_PILOT )
	thread DrainHealthOverTime( vortexSphere, vortexSphere.e.shieldWallFX, duration )

	vortexSphere.SetOwner( player )
	vortexSphere.SetBlocksRadiusDamage( true )
	SetTeam( vortexSphere, player.GetTeam() )
	vortexSphere.SetParent( player, "ORIGIN" )
	vortexSphere.e.shieldWallFX.SetAngles( < 20,0,94 > )
	vortexSphere.e.shieldWallFX.SetOrigin( < 31,0,32 > )

	thread ShieldADSThink( player, vortexSphere, duration )
	/*
	vortexSphere.SetParent( player, "PROPGUN" )
	vortexSphere.e.shieldWallFX.kv.VisibilityFlags = (ENTITY_VISIBLE_TO_FRIENDLY | ENTITY_VISIBLE_TO_ENEMY)
	vortexSphere.SetAngles( < 20,0,100 > )
	vortexSphere.SetOrigin( < 20,0,5 > )
	*/
}

void function ShieldADSThink( entity player, entity vortexSphere, float duration )
{
	float startTime = Time()
	float progressTime

	while( true )
	{
		progressTime = Time()
		if( progressTime - startTime >= duration )
			break
		entity weapon = player.GetActiveWeapon()
		if( IsValid( weapon ) )
			weapon.SetForcedADS()
		if( !IsValid( vortexSphere ) )
			break
		if( !IsAlive( player ) )
			break
		WaitFrame()
	}

	OnThreadEnd(
		function(): ( player, vortexSphere )
		{
			if( IsValid( vortexSphere ) )
				vortexSphere.Destroy()
			if( IsValid( player ) )
			{
				foreach( entity weapon in player.GetMainWeapons() )
				{
					if( IsValid( weapon ) )
					{
						while( weapon.GetForcedADS() )
							weapon.ClearForcedADS()
					}
				}
			}
		}
	)
	
}

entity function CreateGunShieldVortexSphere( entity player, entity vortexWeapon, entity shieldWeapon )
{
	int attachmentID = vortexWeapon.LookupAttachment( "gun_shield" )
	float sphereRadius = TITAN_GUN_SHIELD_RADIUS
	entity vortexSphere = CreateEntity( "vortex_sphere" )
	Assert( vortexSphere )

	SetTargetName( vortexSphere, GUN_SHIELD_WALL )

//	if ( 0 )
//	{
		vortexSphere.kv.spawnflags = SF_ABSORB_BULLETS
		vortexSphere.kv.height = TITAN_GUN_SHIELD_RADIUS * 2
		vortexSphere.kv.radius = TITAN_GUN_SHIELD_RADIUS
//	}
//	else
//	{
//		vortexSphere.kv.spawnflags = SF_ABSORB_CYLINDER | SF_ABSORB_BULLETS
//		vortexSphere.kv.height = TITAN_GUN_SHIELD_RADIUS * 2
//		vortexSphere.kv.radius = TITAN_GUN_SHIELD_RADIUS
//	}

	vortexSphere.e.proto_weakToPilotWeapons = false
	vortexSphere.kv.enabled = 0
	vortexSphere.kv.bullet_fov = PLAYER_SHIELD_WALL_FOV
	vortexSphere.kv.physics_pull_strength = 25
	vortexSphere.kv.physics_side_dampening = 6
	vortexSphere.kv.physics_fov = 360
	vortexSphere.kv.physics_max_mass = 2
	vortexSphere.kv.physics_max_size = 6
	float health
	entity soul = player.GetTitanSoul()

	if( !IsValid( soul ) )
		return

	bool hasShieldUpgrade = false
	if( SoulHasPassive( soul, ePassives.PAS_LEGION_GUNSHIELD ) || shieldWeapon.HasMod( "fd_gun_shield" ) || shieldWeapon.HasMod( "pas_legion_gunshield" ) )
		hasShieldUpgrade = true
	
	if ( hasShieldUpgrade )
		health = PAS_LEGION_SHEILD_HEALTH
	else
		health = TITAN_GUN_SHIELD_HEALTH
	vortexSphere.SetHealth( health )
	vortexSphere.SetMaxHealth( health )

	vortexSphere.SetTakeDamageType( DAMAGE_YES )

	if ( shieldWeapon.HasMod( "npc_infinite_shield" ) )
	{
		vortexSphere.SetInvulnerable()
		SetVortexSphereBulletHitRules( vortexSphere, GunShield_InvulBulletHitRules )
		SetVortexSphereProjectileHitRules( vortexSphere, GunShield_InvulProjectileHitRules )
	}

	DispatchSpawn( vortexSphere )

	vortexSphere.SetOwner( player )
	vortexSphere.SetOwnerWeapon( vortexWeapon )
	vortexSphere.SetParent( vortexWeapon, "gun_shield" )

	vortexWeapon.SetWeaponUtilityEntity( vortexSphere )

	EntFireByHandle( vortexSphere, "Enable", "", 0, null, null )

	// Shield wall fx control point
	entity cpoint = CreateEntity( "info_placement_helper" )
	SetTargetName( cpoint, UniqueString( "shield_wall_controlpoint" ) )
	DispatchSpawn( cpoint )

	vortexSphere.e.shieldWallFX = CreateEntity( "info_particle_system" )
	entity shieldWallFX = vortexSphere.e.shieldWallFX
	shieldWallFX.SetValueForEffectNameKey( FX_TITAN_GUN_SHIELD_WALL )
	shieldWallFX.kv.VisibilityFlags = (ENTITY_VISIBLE_TO_FRIENDLY | ENTITY_VISIBLE_TO_ENEMY) // not owner only
	shieldWallFX.kv.start_active = 1
	SetVortexSphereShieldWallCPoint( vortexSphere, cpoint )
	shieldWallFX.SetOwner( player )
	shieldWallFX.SetParent( player )
	shieldWallFX.kv.cpoint1 = cpoint.GetTargetName()
	shieldWallFX.SetStopType( "destroyImmediately" )
	shieldWallFX.DisableHibernation()
	shieldWallFX.SetLocalOrigin( < 0, 0, 0 > )

	vortexSphere.SetGunVortexAngles( < 0, 0, 180 > )
	vortexSphere.SetGunVortexAttachment( "gun_shield" )
	vortexSphere.SetVortexEffect( shieldWallFX)

	DispatchSpawn( shieldWallFX )

	if ( shieldWeapon.HasMod( "npc_infinite_shield" ) )
	{
		shieldWallFX.e.cpoint.SetOrigin( < 246.0, 134.0, 40.0 > ) // AMPED COLOR
	}
	else
	{
		thread UpdateGunShieldColor( vortexSphere )
	}

	return vortexSphere
}

void function UpdateGunShieldColor( entity vortexSphere )
{
	while ( IsValid( vortexSphere ) )
	{
		UpdateShieldWallColorForFrac( vortexSphere.e.shieldWallFX, GetHealthFrac( vortexSphere ) )
		WaitFrame()
	}
}

var function GunShield_InvulBulletHitRules( entity vortexSphere, var damageInfo )
{
	DamageInfo_SetDamage( damageInfo, 0 )
}

bool function GunShield_InvulProjectileHitRules( entity vortexSphere, entity attacker, bool takesDamageByDefault )
{
	return false
}
#endif

#if CLIENT
void function ServerCallback_PilotCreatedGunShield( int vortexWeaponEHandle, int vortexSphereEHandle )
{
	entity vortexWeapon = GetEntityFromEncodedEHandle( vortexWeaponEHandle )
	entity vortexSphere = GetEntityFromEncodedEHandle( vortexSphereEHandle )

	if ( !IsValid( vortexWeapon ) )
		return

	if ( !IsValid( vortexSphere ) )
		return

	entity player = vortexWeapon.GetWeaponOwner()

	if ( !IsAlive( player ) )
		return

	thread CL_GunShield_Internal( player, vortexWeapon, vortexSphere )
}

void function CL_GunShield_Internal( entity player, entity vortexWeapon, entity vortexSphere )
{
	vortexSphere.EndSignal( "OnDestroy" )
	player.EndSignal( "OnDeath" )
	player.EndSignal( "GunShieldEnd" )

	asset shieldFX = FX_TITAN_GUN_SHIELD_VM
	file.sphereClientFXHandle = vortexWeapon.PlayWeaponEffectReturnViewEffectHandle( shieldFX, $"", "gun_shield_fp" )

	OnThreadEnd(
		function() : ()
		{
			if ( file.sphereClientFXHandle != -1 )
				EffectStop( file.sphereClientFXHandle, true, false )

			file.sphereClientFXHandle = -1
		}
	)

	float oldHealth = float( vortexSphere.GetHealth() )
	while( true )
	{
		float newHealth = float( vortexSphere.GetHealth() )
		UpdateShieldColor( player, oldHealth, newHealth, oldHealth == newHealth )
		oldHealth = newHealth
		wait 0.1
	}
	WaitForever()
}

void function UpdateShieldColor( entity player, float oldValue, float newValue, bool actuallyChanged )
{
	if ( !actuallyChanged )
		return

	if ( player != GetLocalViewPlayer() )
		return

	if ( !IsValid( player ) )
		return

	float shieldFrac = newValue / TITAN_GUN_SHIELD_HEALTH
	vector colorVec = GetShieldTriLerpColor( 1 - shieldFrac )

	if ( EffectDoesExist( file.sphereClientFXHandle ) )
		EffectSetControlPointVector( file.sphereClientFXHandle, 1, colorVec )
}
#endif