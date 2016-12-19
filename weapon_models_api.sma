// Credits:
// s1lent for detecting add type

#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Weapon Models API"
#define VERSION "0.6.0-18"
#define AUTHOR "Mistrick"

#pragma semicolon 1

//#define _DEBUG

#define is_valid_pev(%0) (pev_valid(%0) == 2)

const XO_CBASEPLAYERWEAPON = 4;

const m_pPlayer = 41;
const m_iId = 43;
const m_rgpPlayerItems_CWeaponBox = 34;

enum Forwards
{
	WEAPON_DEPLOY,
	WEAPON_HOLSTER,
	WEAPON_CAN_PICKUP,
	WEAPON_DROP,
	WEAPON_ADD_TO_PLAYER
};

enum
{
	ADD_BY_WEAPONBOX,
	ADD_BY_ARMORY_ENTITY,
	ADD_BY_BUYZONE
}

new g_iForwards[Forwards];
new Float:g_flLastTouchTime;
new bool:g_bIgnoreSetModel = true;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	// forward cs_weapon_deploy(id, weapon, weaponid);
	g_iForwards[WEAPON_DEPLOY] = CreateMultiForward("cs_weapon_deploy", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);

	// forward cs_weapon_holster(id, weapon, weaponid);
	g_iForwards[WEAPON_HOLSTER] = CreateMultiForward("cs_weapon_holster", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);

	// forward cs_weapon_can_pickup(id, weaponbox, weapon, weaponid);
	// should return 1 for block pickup
	g_iForwards[WEAPON_CAN_PICKUP] = CreateMultiForward("cs_weapon_can_pickup", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL, FP_CELL);

	// forward cs_weapon_drop(id, weaponbox, weapon, weaponid);
	// should return 1, if model changed
	g_iForwards[WEAPON_DROP] = CreateMultiForward("cs_weapon_drop", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL, FP_CELL);

	// forward cs_weapon_add_to_player(id, weapon, weaponid, type);
	g_iForwards[WEAPON_ADD_TO_PLAYER] = CreateMultiForward("cs_weapon_add_to_player", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL);

	RegisterWeapons();
	RegisterWeaponDrop();
}
RegisterWeapons()
{
	for(new i = CSW_P228, weapon_name[32]; i < CSW_P90; i++)
	{
		if(get_weaponname(i, weapon_name, charsmax(weapon_name)))
		{
			RegisterHam(Ham_Item_Deploy, weapon_name, "Ham_WeaponDeploy_Post", .Post = true);
			RegisterHam(Ham_Item_Holster, weapon_name, "Ham_WeaponHolster_Post", .Post = true);
			RegisterHam(Ham_Item_AddToPlayer, weapon_name, "Ham_WeaponAddToPlayer_Post", .Post = true);
		}
	}
	register_touch("armoury_entity", "player", "CArmouryEntity__Touch");
	register_touch("weaponbox", "player", "CWeaponBox__Touch");
}
RegisterWeaponDrop()
{
	RegisterHam(Ham_Spawn, "grenade", "Ham_WeaponSpawn_Post", .Post = true);
	RegisterHam(Ham_Spawn, "weaponbox", "Ham_WeaponSpawn_Post", .Post = true);
	register_forward(FM_SetModel, "FM_SetModel_Pre", ._post = false);
}

public plugin_natives()
{
	register_library("weapon_models_api");
}

public Ham_WeaponDeploy_Post(const weapon)
{
	new id = get_pdata_cbase(weapon, m_pPlayer, XO_CBASEPLAYERWEAPON);
	new weaponid = get_pdata_int(weapon, m_iId, XO_CBASEPLAYERWEAPON);

	#if defined _DEBUG
	client_print(0, print_chat, "deploy: id %d, weapon %d, weaponid %d", id, weapon, weaponid);
	#endif // _DEBUG

	new ret; ExecuteForward(g_iForwards[WEAPON_DEPLOY], ret, id, weapon, weaponid);
}

public Ham_WeaponHolster_Post(const weapon)
{
	new id = get_pdata_cbase(weapon, m_pPlayer, XO_CBASEPLAYERWEAPON);
	new weaponid = get_pdata_int(weapon, m_iId, XO_CBASEPLAYERWEAPON);

	#if defined _DEBUG
	client_print(0, print_chat, "holster: id %d, weapon %d, weaponid %d", id, weapon, weaponid);
	#endif // _DEBUG

	new ret; ExecuteForward(g_iForwards[WEAPON_HOLSTER], ret, id, weapon, weaponid);
}

public CArmouryEntity__Touch(ent, id)
{
    g_flLastTouchTime = get_gametime();
}

public CWeaponBox__Touch(ent, id)
{
	#define MAX_ITEM_TYPES	6
	
	for(new i, weapon; i < MAX_ITEM_TYPES; i++)
	{
		weapon = get_pdata_cbase(ent, m_rgpPlayerItems_CWeaponBox + i, XO_CBASEPLAYERWEAPON);

		if(is_valid_pev(weapon))
		{
			new id = pev(ent, pev_owner);
			new weaponid = get_pdata_int(weapon, m_iId, XO_CBASEPLAYERWEAPON);

			#if defined _DEBUG
			client_print(0, print_chat, "can pickup: id %d, weaponbox %d, weapon %d, weaponid %d", id, ent, weapon, weaponid);
			#endif // _DEBUG

			new ret; ExecuteForward(g_iForwards[WEAPON_CAN_PICKUP], ret, id, ent, weapon, weaponid);

			if(ret)
			{
				return PLUGIN_HANDLED;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public Ham_WeaponAddToPlayer_Post(const weapon, const id)
{
	new weaponid = get_pdata_int(weapon, m_iId, XO_CBASEPLAYERWEAPON);

	#if defined _DEBUG
	client_print(0, print_chat, "add_to_player: id %d, weapon %d, weaponid %d", id, weapon, weaponid);
	#endif // _DEBUG

	new type;

	if (pev(weapon, pev_owner) > 0)
	{
		type = ADD_BY_WEAPONBOX;
	}
	else if(get_gametime() == g_flLastTouchTime)
	{
		type = ADD_BY_ARMORY_ENTITY;
	}
	else
	{
		type = ADD_BY_BUYZONE;
	}

	new ret; ExecuteForward(g_iForwards[WEAPON_ADD_TO_PLAYER], ret, id, weapon, weaponid, type);
}

public Ham_WeaponSpawn_Post(const ent)
{
	if (is_valid_pev(ent))
	{
		g_bIgnoreSetModel = false;
	}
}
public FM_SetModel_Pre(const ent)
{
	if(g_bIgnoreSetModel || !is_valid_pev(ent)) return FMRES_IGNORED;

	g_bIgnoreSetModel = true;

	new classname[32]; pev(ent, pev_classname, classname, charsmax(classname));
	if(equal(classname, "grenade"))
	{
		new id = pev(ent, pev_owner);
		new weaponid = fm_cs_get_grenade_type(ent);

		#if defined _DEBUG
		client_print(0, print_chat, "throw grenade: id %d, weapon %d, weaponid %d", id, ent, weaponid);
		#endif // _DEBUG

		new ret; ExecuteForward(g_iForwards[WEAPON_DROP], ret, id, ent, 0, weaponid);

		if(ret)
		{
			return FMRES_SUPERCEDE;
		}
		
		return FMRES_IGNORED;
	}

	#define MAX_ITEM_TYPES	6
	
	for(new i, weapon; i < MAX_ITEM_TYPES; i++)
	{
		weapon = get_pdata_cbase(ent, m_rgpPlayerItems_CWeaponBox + i, XO_CBASEPLAYERWEAPON);

		if(is_valid_pev(weapon))
		{
			new id = pev(ent, pev_owner);
			new weaponid = get_pdata_int(weapon, m_iId, XO_CBASEPLAYERWEAPON);

			#if defined _DEBUG
			client_print(0, print_chat, "drop: id %d, weaponbox %d, weapon %d, weaponid %d", id, ent, weapon, weaponid);
			#endif // _DEBUG

			new ret; ExecuteForward(g_iForwards[WEAPON_DROP], ret, id, ent, weapon, weaponid);

			if(ret)
			{
				return FMRES_SUPERCEDE;
			}
		}
	}
	
	return FMRES_IGNORED;
}

// work only for "grenade" classname
stock fm_cs_get_grenade_type(index)
{
	const m_iTeam = 114;
	new bits = get_pdata_int(index, m_iTeam);

	if (bits & (1 << 0))
		return CSW_HEGRENADE;
	else if (bits & (1 << 1))
		return CSW_SMOKEGRENADE;
	else if (!bits)
		return CSW_FLASHBANG;

	return 0;
}
