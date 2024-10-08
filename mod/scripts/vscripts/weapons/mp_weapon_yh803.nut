untyped


global function OnWeaponActivate_yh803Rocket

#if SERVER
global function OnWeaponNpcPrimaryAttack_yh803Rocket
global function OnWeaponNpcPrimaryAttack_weapon_yh803
#endif // #if SERVER


void function OnWeaponActivate_yh803Rocket( entity weapon )
{
}

function SetMissileTarget( entity missile, entity target, entity weaponOwner )
{
	Assert( IsServer() )
	Assert( IsValid( weaponOwner ) )

	if ( !IsAlive( target ) )
		return

	if ( !target.IsPlayer() && !target.IsNPC() )
		return

	if ( target.GetTeam() == weaponOwner.GetTeam() )
		return

	missile.SetMissileTarget( target, Vector( 0, 0, 0 ) )
	missile.SetHomingSpeeds( 100, 0 )	// speed, speed for dodging player
}

#if SERVER
var function OnWeaponNpcPrimaryAttack_yh803Rocket( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	// "rocket_pod_fire" does not exist
	//weapon.EmitWeaponSound( "rocket_pod_fire" )
	weapon.EmitWeaponNpcSound( LOUD_WEAPON_AI_SOUND_RADIUS_MP, 0.2 )

	entity missile = FireWeaponMissile_RecordData( weapon, attackParams.pos, attackParams.dir, 1, damageTypes.largeCaliberExp, damageTypes.largeCaliberExp, false, PROJECTILE_NOT_PREDICTED )
	if ( missile )
	{
		EmitSoundOnEntity( missile, "Weapon_Sidwinder_Projectile" )
		missile.InitMissileForRandomDriftFromWeaponSettings( attackParams.pos, attackParams.dir )

		// need aim ahead of the enemy tech.
		// entity weaponOwner = weapon.GetOwner()
		// entity target = weaponOwner.GetEnemy()
		// SetMissileTarget( missile, target, weaponOwner )

		// modified here: helps us get correct damageSourceId display name
		#if SERVER
			missile.ProjectileSetDamageSourceID( eDamageSourceId.mp_weapon_turretrockets )
		#endif
	}

	// modified here: do reduced effect for sentry turrets
	entity owner = weapon.GetWeaponOwner()
	if ( owner.GetClassName() == "npc_turret_sentry" )
	{
		weapon.PlayWeaponEffect( $"", $"wpn_muzzleflash_smg", "muzzle_flash" ) // $"wpn_muzzleflash_40mm"
		weapon.PlayWeaponEffect( $"", $"P_wpn_muzzleflash_mgl_FULL", "muzzle_flash" )
	}
	else // mega turrets
		weapon.PlayWeaponEffect( $"wpn_muzzleflash_xo_rocket", $"wpn_muzzleflash_xo_rocket", "muzzle_flash" )
}

var function OnWeaponNpcPrimaryAttack_weapon_yh803( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	entity weaponOwner = weapon.GetWeaponOwner()
	if ( !weaponOwner.ai.readyToFire ) // this is true by default
		return 0

	weapon.FireWeaponBullet( attackParams.pos, attackParams.dir, 1, DF_BULLET )
	return 1
}
#endif // #if SERVER

