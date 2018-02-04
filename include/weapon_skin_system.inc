#if defined _weapon_skin_system_included
  #endinput
#endif
#define _weapon_skin_system_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib weapon_skin_system
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib weapon_skin_system
	#endif
#else
	#pragma library weapon_skin_system
#endif

enum
{
	WEAPON_CAN_PICKUP,
	WEAPON_BLOCK_PICKUP
};

/**
 * Called when load skins from file.
 * 
 * @param index						Skin index
 * @param weaponid					Skin CSW_ const
 * @param name						Skin name
 */
forward wss_loaded_skin(index, weaponid, const name[]);

/**
 * Get weapon skin.
 * 
 * @note Should call in plugin_precache()
 *
 * @param weaponid					Skin CSW_ const
 * @param skinname					Skin name
 * @param model_v					Skin model_v
 * @param model_p					Skin model_p
 * @param model_w					Skin model_w
 *
 * @return							Skin index
 */
native wss_register_weapon(weaponid, skinname[], model_v[], model_p[], model_w[]);

/**
 * Get weapon skin.
 * 
 * @param weapon					Weapon enity index
 */
native wss_get_weapon_skin_index(weapon);

/**
 * Set weapon skin.
 * 
 * @param weapon					Weapon enity index
 * @param skin						Weapon skin index
 */
native wss_set_weapon_skin_index(weapon, skin);

/**
 * Get skin name by index.
 * 
 * @param skin_index				Skin index
 * @param name						String for name
 * @param len						Max string len
 */
native wss_get_skin_name(skin_index, name[], len);

/**
 * Change player weapon skin.
 * If weaponid is NULL then reset all player skins.
 * 
 * wss_set_user_skin(id, 0) - reset all player's skins
 * wss_set_user_skin(id, CSW_AK47) - reset only ak47 skin
 * 
 * @param id						Player index
 * @param weaponid					Weapon CSW_ const
 * @param skin_index				Skin index from wss_loaded_skin()
 */
native wss_set_user_skin(id, weaponid, skin_index = 0);

/**
 * Called when weapon deployed.
 * 
 * @param id					Player index.
 * @param weapon				Weapon entity index.
 * @param weaponid				CSW_ const.
 * @param skin					Skin index.
 */
forward wss_weapon_deploy(id, weapon, weaponid, skin);

/**
 * Called when weapon holstered.
 * 
 * @param id					Player index.
 * @param weapon				Weapon entity index.
 * @param weaponid				CSW_ const.
 * @param skin					Skin index.
 */
forward wss_weapon_holster(id, weapon, weaponid, skin);

/**
 * Called when player touches weapon.
 * Forward should return WEAPON_BLOCK_PICKUP for block pickup
 * 
 * @param id					Player index.
 * @param weaponbox				Weaponbox entity index.
 * @param weapon				Weapon entity index.
 * @param weaponid				CSW_ const.
 * @param skin					Skin index.
 */
forward wss_weapon_can_pickup(id, weaponbox, weapon, weaponid, skin);

/**
 * Called when weapon droped.
 * 
 * @param id					Player index.
 * @param weaponbox				Weaponbox entity index.
 * @param weapon				Weapon entity index.
 * @param weaponid				CSW_ const.
 * @param skin					Skin index.
 */
forward wss_weapon_drop(id, weaponbox, weapon, weaponid, skin);
