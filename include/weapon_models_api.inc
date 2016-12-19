#if defined _weapon_models_api_included
  #endinput
#endif
#define _weapon_models_api_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib weapon_models_api
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib weapon_models_api
	#endif
#else
	#pragma library weapon_models_api
#endif

enum
{
	WEAPON_CAN_PICKUP,
	WEAPON_BLOCK_PICKUP
};

enum
{
	WEAPON_MODEL_IGNORED,
	WEAPON_MODEL_CHANGED
};

enum
{
	ADD_BY_WEAPONBOX,
	ADD_BY_ARMORY_ENTITY,
	ADD_BY_BUYZONE
};

/**
 * Called when weapon deployed.
 * 
 * @param id					Player index.
 * @param weapon				Weapon entity index.
 * @param weaponid				CSW_ const.
 */
forward cs_weapon_deploy(id, weapon, weaponid);

/**
 * Called when weapon holstered.
 * 
 * @param id					Player index.
 * @param weapon				Weapon entity index.
 * @param weaponid				CSW_ const.
 */
forward cs_weapon_holster(id, weapon, weaponid);

/**
 * Called when weapon droped.
 * Forward should return WEAPON_BLOCK_PICKUP for block pickup
 * 
 * @param id					Player index.
 * @param weaponbox				Weaponbox entity index.
 * @param weapon				Weapon entity index.
 * @param weaponid				CSW_ const.
 */
forward cs_weapon_can_pickup(id, weaponbox, weapon, weaponid);

/**
 * Called when weapon droped.
 * Forward should return WEAPON_MODEL_CHANGED if weaponbox model changed
 * 
 * @param id					Player index.
 * @param weaponbox				Weaponbox entity index.
 * @param weapon				Weapon entity index.
 * @param weaponid				CSW_ const.
 */
forward cs_weapon_drop(id, weaponbox, weapon, weaponid);

/**
 * Called when weapon added to player.
 * 
 * @param id					Player index.
 * @param weapon				Weapon entity index.
 * @param weaponid				CSW_ const.
 * @param type					Add type.
 */
forward cs_weapon_add_to_player(id, weapon, weaponid, type);
