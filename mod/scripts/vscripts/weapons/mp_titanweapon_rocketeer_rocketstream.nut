untyped

global function MpTitanweaponRocketeetRocketStream_Init

// modified callback
global function OnWeaponActivate_TitanWeapon_Rocketeer_RocketStream
//
global function OnWeaponPrimaryAttack_TitanWeapon_Rocketeer_RocketStream
global function OnWeaponOwnerChanged_TitanWeapon_Rocketeer_RocketStream
global function OnWeaponDeactivate_TitanWeapon_Rocketeer_RocketStream

global function OnWeaponStartZoomIn_TitanWeapon_Rocketeer_RocketStream
global function OnWeaponStartZoomOut_TitanWeapon_Rocketeer_RocketStream

#if SERVER
global function OnWeaponNpcPrimaryAttack_TitanWeapon_Rocketeer_RocketStream
#endif // #if SERVER

#if CLIENT
global function OnClientAnimEvent_TitanWeapon_Rocketeer_RocketStream
#endif // #if CLIENT


const DRAW_DEBUG = 0
const DEBUG_FAIL = 0
const MERGEDEBUG = 0
const DEBUG_TIME = 5
const MIN_HEIGHT = 70
const POINT_FROM = 0
const POINT_TO = 1
const POINT_NEXT = 2
const POINT_FUTURE = 3
const TRACE_DIST_PER_SECTION = 800
const WALL_BUFFER = 74
const STEEPNESS_DOT = 0.6
const MISSILE_LOOKAHEAD = 150 // 150
const MATCHSLOPERISE = 40 // 32
const MISSILE_LIFETIME = 8.0
const FUDGEPOINT_RIGHT = 100
const FUDGEPOINT_UP = 150
const PROX_MISSILE_RANGE = 160
const BURN_CLUSTER_EXPLOSION_INNER_RADIUS = 150
const BURN_CLUSTER_EXPLOSION_RADIUS = 220
const BURN_CLUSTER_EXPLOSION_DAMAGE = 66
const BURN_CLUSTER_EXPLOSION_DAMAGE_HEAVY_ARMOR = 100
const BURN_CLUSTER_NPC_EXPLOSION_DAMAGE = 66
const BURN_CLUSTER_NPC_EXPLOSION_DAMAGE_HEAVY_ARMOR = 100

const asset AMPED_SHOT_PROJECTILE = $"models/weapons/bullets/temp_triple_threat_projectile_large.mdl"


function MpTitanweaponRocketeetRocketStream_Init()
{
	RegisterSignal( "FiredWeapon" )

	PrecacheParticleSystem( $"wpn_muzzleflash_xo_rocket_FP" )
	PrecacheParticleSystem( $"wpn_muzzleflash_xo_rocket" )
	PrecacheParticleSystem( $"wpn_muzzleflash_xo_fp" )
	PrecacheParticleSystem( $"P_muzzleflash_xo_mortar" )

#if SERVER
	PrecacheModel( AMPED_SHOT_PROJECTILE )

	AddCallback_OnVortexHitProjectile( OnVortexHitProjectile_QuadRocket )
#endif // #if SERVER
}

// modified callback to trigger cluster on vortex hit
#if SERVER
void function OnVortexHitProjectile_QuadRocket( entity weapon, entity vortexSphere, entity attacker, entity projectile, vector contactPos )
{
	if ( projectile.ProjectileGetWeaponClassName() == "mp_titanweapon_rocketeer_rocketstream" )
	{
		array<string> mods = Vortex_GetRefiredProjectileMods( projectile ) // I don't care, let's break vanilla behavior
		
		// modded weapon
		// burn mod quad rocket will trigger cluster explosion on impact with vortex sphere( mini_clusters won't )
		if ( mods.contains( "burn_mod_titan_rocket_launcher" ) )
		{
			vector pos = contactPos
			// same build as respawn's hardcode in CodeCallback_OnVortexHitProjectile()
			vector normal = projectile.GetVelocity() * -1
			normal = Normalize( normal )
			// do a fake callback to trigger it's cluster explosion
			OnProjectileCollision_SpiralMissile( projectile, pos, normal, vortexSphere, 0, false )
		}
	}
}
#endif

// modified callback for better fixing weapon mod when switch from offhand weapon
void function OnWeaponActivate_TitanWeapon_Rocketeer_RocketStream( entity weapon )
{
	// modded weapon
	if ( weapon.HasMod( "brute4_quad_rocket" ) )
		return OnWeaponActivate_TitanWeapon_Brute4_QuadRocket( weapon )
	//

	// modded weapon: TF|1 quad rocket mod
	if ( weapon.HasMod( "rapid_fire_missiles" ) )
		return 

	// defensive fix for sometimes player don't gain single shot mod
	// this is not vanilla behavior, but vanilla also don't have this weapon appeared in MP, so I'd fix it
	if ( weapon.IsWeaponInAds() && !weapon.HasMod( "mini_clusters" ) && !weapon.HasMod( "rocketstream_fast" ) )
		OnWeaponStartZoomIn_TitanWeapon_Rocketeer_RocketStream( weapon )
}

void function OnWeaponStartZoomIn_TitanWeapon_Rocketeer_RocketStream( entity weapon )
{
	// modded weapon
	if ( weapon.HasMod( "brute4_quad_rocket" ) )
		return OnWeaponStartZoomIn_TitanWeapon_Brute4_QuadRocket( weapon )
	//

	// modded weapon: TF|1 quad rocket mod
	if ( weapon.HasMod( "rapid_fire_missiles" ) )
		return 

	// vanilla behavior( actually modified )
	// should have client sync for mods adding
//#if SERVER
	// cluster missiles and fast shots
	if ( weapon.HasMod( "burn_mod_titan_rocket_launcher" ) ||  weapon.HasMod( "rocketstream_fast" ) )
		return

	// vanilla rocketeer_ammo_swap fix
	if ( weapon.HasMod( "mini_clusters" ) )
		return

	array<string> mods = weapon.GetMods()
	mods.append( "rocketstream_fast" )
	
	if ( weapon.HasMod( "brute_rocket" ) ) // brute additional mod
		mods.append( "brute_rocket_fast_shot" )

	weapon.SetMods( mods )

//#else // CLIENT
#if CLIENT
	entity weaponOwner = weapon.GetWeaponOwner()
	if ( weaponOwner == GetLocalViewPlayer() )
		EmitSoundOnEntity( weaponOwner, "Weapon_Particle_Accelerator_WindUp_1P" )
#endif // SERVER

	//weapon.PlayWeaponEffectNoCull( $"wpn_arc_cannon_electricity_fp", $"wpn_arc_cannon_electricity", "muzzle_flash" )
	//weapon.PlayWeaponEffectNoCull( $"wpn_arc_cannon_charge_fp", $"wpn_arc_cannon_charge", "muzzle_flash" )
	//weapon.EmitWeaponSound( "arc_cannon_charged_loop" )
}

void function OnWeaponStartZoomOut_TitanWeapon_Rocketeer_RocketStream( entity weapon )
{
	// modded weapon
	if ( weapon.HasMod( "brute4_quad_rocket" ) )
		return OnWeaponStartZoomOut_TitanWeapon_Brute4_QuadRocket( weapon )
	//

	// modded weapon: TF|1 quad rocket mod
	if ( weapon.HasMod( "rapid_fire_missiles" ) )
		return 

	// vanilla behavior( actually modified )
	// should have client sync for mods removing
//#if SERVER
	array<string> mods = weapon.GetMods()
	mods.fastremovebyvalue( "rocketstream_fast" )

	if ( weapon.HasMod( "brute_rocket" ) ) // brute additional mod
		mods.fastremovebyvalue( "brute_rocket_fast_shot" )

	weapon.SetMods( mods )
//#endif
	//weapon.StopWeaponEffect( $"wpn_arc_cannon_charge_fp", $"wpn_arc_cannon_charge" )
	//weapon.StopWeaponEffect( $"wpn_arc_cannon_electricity_fp", $"wpn_arc_cannon_electricity" )
	//weapon.StopWeaponSound( "arc_cannon_charged_loop" )
}


#if CLIENT
void function OnClientAnimEvent_TitanWeapon_Rocketeer_RocketStream( entity weapon, string name )
{
	// modded weapon
	if ( weapon.HasMod( "brute4_quad_rocket" ) )
		return OnClientAnimEvent_TitanWeapon_Brute4_QuadRocket( weapon, name )
	//

	// vanilla behavior
	if ( name == "muzzle_flash" )
	{
		weapon.PlayWeaponEffect( $"wpn_muzzleflash_xo_fp", $"wpn_muzzleflash_xo_rocket", "muzzle_flash" )
	}
}
#endif // #if CLIENT

var function OnWeaponPrimaryAttack_TitanWeapon_Rocketeer_RocketStream( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	// modded weapon
	if ( weapon.HasMod( "brute4_quad_rocket" ) )
		return OnWeaponPrimaryAttack_TitanWeapon_Brute4_QuadRocket( weapon, attackParams )
	//

	// misc fix: disallow weapon firing when not fully ads
	// so we don't get weird desync condition
	if ( bool( GetCurrentPlaylistVarInt( "rocketeer_rocketstream_fix", 0 ) ) || weapon.HasMod( "rocketeer_rocketstream_fix" ) )
	{
		entity owner = weapon.GetWeaponOwner()
		float zoomFrac = owner.GetZoomFrac()
		if ( zoomFrac < 1 && zoomFrac > 0)
			return 0
	}

	// vanilla behavior
	#if CLIENT
		if ( !weapon.ShouldPredictProjectiles() )
			return 1
	#endif

	return FireMissileStream( weapon, attackParams, PROJECTILE_PREDICTED )
}

#if SERVER
var function OnWeaponNpcPrimaryAttack_TitanWeapon_Rocketeer_RocketStream( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	// modded weapon
	if ( weapon.HasMod( "brute4_quad_rocket" ) )
		return OnWeaponNpcPrimaryAttack_TitanWeapon_Brute4_QuadRocket( weapon, attackParams )
	//

	// vanilla behavior
	return FireMissileStream( weapon, attackParams, PROJECTILE_NOT_PREDICTED )
}
#endif // #if SERVER

int function FireMissileStream( entity weapon, WeaponPrimaryAttackParams attackParams, bool predicted )
{
	weapon.EmitWeaponNpcSound( LOUD_WEAPON_AI_SOUND_RADIUS_MP, 0.2 )
	bool adsPressed = weapon.IsWeaponInAds()
	bool hasBurnMod = weapon.HasMod( "burn_mod_titan_rocket_launcher" )
	bool hasAmmoSwap = weapon.HasMod( "mini_clusters" ) // modified to add back rocketeer ammo swap
	bool has_s2s_npcMod = weapon.HasMod( "sp_s2s_settings_npc" )
	bool has_mortar_mod = weapon.HasMod( "coop_mortar_titan" )
	bool hasRapidShot = weapon.HasMod( "rapid_fire_missiles" ) // modded weapon: TF|1 quad rocket mod

	// defensive fix for sometimes player don't gain single shot mod, or retain ads mod trhough offhand weapons
	// this is not vanilla behavior, but vanilla also don't have this weapon appeared in MP, so I'd fix it
    if ( adsPressed && !hasAmmoSwap && !weapon.HasMod( "rocketstream_fast" ) && !hasRapidShot )
		OnWeaponStartZoomIn_TitanWeapon_Rocketeer_RocketStream( weapon )
	else if ( !adsPressed && weapon.HasMod( "rocketstream_fast" ) )
		OnWeaponStartZoomOut_TitanWeapon_Rocketeer_RocketStream( weapon )

	// modified
	if ( hasAmmoSwap )
	{
		//weapon.EmitWeaponSound_1p3p( "Weapon_Titan_Rocket_Launcher_Amped_Fire_1P", "Weapon_Titan_Rocket_Launcher_Amped_Fire_3P" )
		weapon.EmitWeaponSound_1p3p( "Weapon_Archer_Fire_1P", "Weapon_Archer_Fire_3P" )
		// welp this sound maybe not that good for TF2
		//weapon.EmitWeaponSound_1p3p( "weapon_titan_rocket_launcher_fire_1p", "weapon_titan_rocket_launcher_fire_3p" )
	}
	else if ( adsPressed || hasBurnMod || hasRapidShot ) 
		weapon.EmitWeaponSound_1p3p( "Weapon_Titan_Rocket_Launcher_Amped_Fire_1P", "Weapon_Titan_Rocket_Launcher_Amped_Fire_3P" )
	else
	{
		weapon.EmitWeaponSound_1p3p( "Weapon_Titan_Rocket_Launcher.RapidFire_1P", "Weapon_Titan_Rocket_Launcher.RapidFire_3P" )
		// don't know why tf2 won't use these sound
		// guess I'd use it for ammo swap!
		//weapon.EmitWeaponSound_1p3p( "weapon_titan_rocket_launcher_fire_1p", "weapon_titan_rocket_launcher_fire_3p" )
	}

	entity weaponOwner = weapon.GetWeaponOwner()
	if ( !IsValid( weaponOwner ) )
		return 0

	// remove hasBurnMod check to recover ttf1 burn mod behavior
	// causes desync but whatever, should install it on client-side if we want to use them
	// if ( !adsPressed && !hasBurnMod && !has_s2s_npcMod && !has_mortar_mod )
	if ( !adsPressed && !hasAmmoSwap && !has_s2s_npcMod && !has_mortar_mod && !hasRapidShot )
	{
		int shots = minint( weapon.GetProjectilesPerShot(), weapon.GetWeaponPrimaryClipCount() )
		FireMissileStream_Spiral( weapon, attackParams, predicted, shots )
		return shots
	}
	else
	{
		//attackParams.pos = attackParams.pos + Vector( 0, 0, -20 )
		// float missileSpeed = 2800

		// wrap missile speed into function
		float missileSpeed = GetMissileSpeedForRocketeer( weapon, true )
		/*
		float missileSpeed = 6000
		if ( has_s2s_npcMod || has_mortar_mod )
			missileSpeed = 2500
		*/

		int impactFlags = (DF_IMPACT | DF_GIB | DF_KNOCK_BACK)

		entity missile = FireWeaponMissile_RecordData( weapon, attackParams.pos, attackParams.dir, missileSpeed, impactFlags, damageTypes.explosive | DF_KNOCK_BACK, false, predicted )

		if ( missile )
		{
			SetTeam( missile, weaponOwner.GetTeam() )
#if SERVER
			string whizBySound = "Weapon_Sidwinder_Projectile"
			EmitSoundOnEntity( missile, whizBySound )
			if ( weapon.w.missileFiredCallback != null )
			{
				weapon.w.missileFiredCallback( missile, weaponOwner )
			}
#endif // #if SERVER
		}

		return 1
	}

	unreachable
}


int function FindIdealMissileConfiguration( int numMissiles, int i )
{
	//We're locked into 4 missiles from passing in 0-3, and in the case of 2 we want to fire the horizontal missiles for aesthetic reasons.
	int idealMissile
	if ( numMissiles == 2 )
	{
		if ( i == 0 )
			idealMissile = 1
		else
			idealMissile = 3
	}
	else
	{
		idealMissile = i
	}

	return idealMissile
}

// wrap missile speed into function
float function GetMissileSpeedForRocketeer( entity weapon, bool isSingleShot = false )
{
	float missileSpeed
	if ( !isSingleShot ) // missile sprial
	{
		// default speed... actually pretty slow
		missileSpeed = 1200

		entity weaponOwner = weapon.GetWeaponOwner()
		if ( IsSingleplayer() && weaponOwner.IsPlayer() )
			missileSpeed = 2000

		// HACK for increasing missile speed in MP. this does not trigger server-side visual fix so be sure to install on client-side!
		if ( weapon.HasMod( "increased_projectile_speed" ) )
			missileSpeed = 2000

		// the high projectile speed is a bug I made before
		// actually it don't desync very much, just keep it
		// otherwise it will be too difficult to land shots with this weapon
		if ( weapon.HasMod( "brute_rocket" ) ) // brute specific
			missileSpeed = 3000
	}
	else // single shot
	{
		// default missile speed
		missileSpeed = 6000

		// modded brute titan
		if ( weapon.HasMod( "brute_rocket" ) ) // brute specific
			missileSpeed = 8000
		
		// adding burn mod check
		if ( weapon.HasMod( "burn_mod_titan_rocket_launcher" ) || weapon.HasMod( "sp_s2s_settings_npc" ) || weapon.HasMod( "coop_mortar_titan" ) )
		{
			missileSpeed = 2500
			// HACK for increasing missile speed in MP. this does not trigger server-side visual fix so be sure to install on client-side!
			if ( weapon.HasMod( "increased_projectile_speed" ) )
				missileSpeed *= 1.5
		}

		// modded weapon: TF|1 weapon mod
		if ( weapon.HasMod( "rapid_fire_missiles" ) )
			missileSpeed = 2300
	}

	return missileSpeed
}

void function FireMissileStream_Spiral( entity weapon, WeaponPrimaryAttackParams attackParams, bool predicted, int numMissiles = 4 )
{
	//attackParams.pos = attackParams.pos + Vector( 0, 0, -20 )
	array<entity> missiles
	array<vector> straightDir
	
	// wrap missile speed into a function
	float missileSpeed = GetMissileSpeedForRocketeer( weapon )
	/*
	float missileSpeed = 1200

	entity weaponOwner = weapon.GetWeaponOwner()
	if ( IsSingleplayer() && weaponOwner.IsPlayer() )
		missileSpeed = 2000
	*/

	int impactFlags = (DF_IMPACT | DF_GIB | DF_KNOCK_BACK)

	for ( int i = 0; i < numMissiles; i++ )
	{
		entity missile = FireWeaponMissile_RecordData( weapon, attackParams.pos, attackParams.dir, missileSpeed, impactFlags, damageTypes.explosive | DF_KNOCK_BACK, false, predicted )
		if ( missile )
		{
			//Spreading out the missiles
			int missileNumber = FindIdealMissileConfiguration( numMissiles, i )
			missile.InitMissileSpiral( attackParams.pos, attackParams.dir, missileNumber, false, false )

			//missile.s.launchTime <- Time()
			// each missile knows about the other missiles, so they can all blow up together
			//missile.e.projectileGroup = missiles
			missile.kv.lifetime = MISSILE_LIFETIME
			missile.SetSpeed( missileSpeed );
			SetTeam( missile, weapon.GetWeaponOwner().GetTeam() )

			missiles.append( missile )

#if SERVER
			EmitSoundOnEntity( missile, "Weapon_Sidwinder_Projectile" )
#endif // #if SERVER
		}
	}
}

void function OnWeaponOwnerChanged_TitanWeapon_Rocketeer_RocketStream( entity weapon, WeaponOwnerChangedParams changeParams )
{
	// modded weapon
	if ( weapon.HasMod( "brute4_quad_rocket" ) )
		return // no callback for brute4
	//

	// vanilla behavior
	#if SERVER
	weapon.w.missileFiredCallback = null

	// modified behavior
	// idk why respawn make run_and_gun for quad rocket, try to disable it's effect on server-side
	Disable_RunAndGun_ServerSide( weapon, changeParams )
	#endif
}

void function OnWeaponDeactivate_TitanWeapon_Rocketeer_RocketStream( entity weapon )
{
	// modded weapon
	if ( weapon.HasMod( "brute4_quad_rocket" ) )
		return // no callback for brute4
	//

	// vanilla behavior is empty
}