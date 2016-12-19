#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <weapon_models_api>

#define PLUGIN "Weapon Skin System"
#define VERSION "0.5.0-45"
#define AUTHOR "Mistrick"

#pragma semicolon 1

#define DEFAULT_SKIN_MENU

#define MODEL_NOT_SET 0

#define is_valid_pev(%0) (pev_valid(%0) == 2)
#define get_weapon_skin(%0) pev(%0, pev_iuser4)
#define set_weapon_skin(%0,%1) set_pev(%0, pev_iuser4, %1)

const XO_CBASEPLAYER = 5;
const XO_CBASEPLAYERWEAPON = 4;

const m_pPlayer = 41;
const m_pNext = 42;
const m_iId = 43;
const m_pActiveItem = 373;
const m_rgpPlayerItems_CBasePlayer = 367;

enum _:SkinInfo
{
	WeaponID,
	SkinName[32],
	ModelV,
	ModelP,
	ModelW[64]
};

new const FILE_MODELS[] = "weapon_skins.ini";

new Array:g_aWeaponSkins;
new g_LoadedWeapons;
new g_iWeaponSkinsCount;
new g_iPlayerSkins[33][32];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	#if defined DEFAULT_SKIN_MENU
	register_clcmd("say /skins", "Command_ChangeSkin");
	register_clcmd("say /skinreset", "Command_ResetSkin");
	#endif // DEFAULT_SKIN_MENU
}

public plugin_precache()
{
	new file_path[128]; get_localinfo("amxx_configsdir", file_path, charsmax(file_path));
	format(file_path, charsmax(file_path), "%s/%s", file_path, FILE_MODELS);

	new file = fopen(file_path, "rt");

	if(!file)
	{
		set_fail_state("File not found!");
	}

	g_aWeaponSkins = ArrayCreate(SkinInfo, 1);

	// forward wss_loaded_skin(index, weaponid, name[]);
	new fwd = CreateMultiForward("wss_loaded_skin", ET_IGNORE, FP_CELL, FP_CELL, FP_STRING);

	new buffer[256], weapon_name[32], skin_name[32], model_v[64], model_p[64], model_w[64];
	new weaponid, skin_info[SkinInfo];
	new ret;

	while(!feof(file))
	{
		fgets(file, buffer, charsmax(buffer));

		if(!buffer[0] || buffer[0] == ';') continue;

		parse(buffer, weapon_name, charsmax(weapon_name), skin_name, charsmax(skin_name), model_v, charsmax(model_v), model_p, charsmax(model_p), model_w, charsmax(model_w));
		weaponid = get_weapon_csw(weapon_name);

		if(!weaponid) continue;

		skin_info[WeaponID] = weaponid;

		g_LoadedWeapons |= (1 << weaponid);

		if(model_v[0] && file_exists(model_v))
		{
			skin_info[ModelV] = engfunc(EngFunc_AllocString, model_v);
			precache_model(model_v);
		}
		if(model_p[0] && file_exists(model_p))
		{
			skin_info[ModelP] = engfunc(EngFunc_AllocString, model_p);
			precache_model(model_p);
		}
		if(model_w[0] && file_exists(model_w))
		{
			copy(skin_info[ModelW], charsmax(skin_info[ModelW]), model_w);
			precache_model(model_w);
		}
		copy(skin_info[SkinName], charsmax(skin_info[SkinName]), skin_name);

		ExecuteForward(fwd, ret, g_iWeaponSkinsCount + 1, weaponid, skin_name);

		ArrayPushArray(g_aWeaponSkins, skin_info);
		g_iWeaponSkinsCount++;

		skin_info[ModelV] = MODEL_NOT_SET; skin_info[ModelP] = MODEL_NOT_SET; skin_info[ModelW] = MODEL_NOT_SET;
	}

	fclose(file);

	if(!g_iWeaponSkinsCount)
	{
		ArrayDestroy(g_aWeaponSkins);
		set_fail_state("File is empty!");
	}
}

public plugin_natives()
{
	register_library("weapon_skin_system");
	register_native("wss_get_weapon_skin_index", "native_get_weapon_skin_index");
	register_native("wss_get_skin_name", "native_get_skin_name");
	register_native("wss_set_user_skin", "native_set_user_skin");
}

// native wss_get_weapon_skin_index(weapon);
public native_get_weapon_skin_index(plugin, params)
{
	enum { arg_weapon = 1 };

	new weapon = get_param(arg_weapon);

	return get_weapon_skin(weapon);
}

// native wss_get_skin_name(skin, name[], len);
public native_get_skin_name(plugin, params)
{
	enum
	{
		arg_skin = 1,
		arg_name,
		arg_len
	};

	new skin = get_param(arg_skin);

	if(skin < 1 || skin > g_iWeaponSkinsCount)
	{
		log_error(AMX_ERR_NATIVE, "[WSS] Get skin name: wrong skin index! index %d", skin);
		return 0;
	}

	new skin_info[SkinInfo];
	ArrayGetArray(g_aWeaponSkins, skin - 1, skin_info);
	set_string(arg_name, skin_info[SkinName], get_param(arg_len));

	return 1;
}

// native wss_set_user_skin(id, weaponid, skin_index);
public native_set_user_skin(plugin, params)
{
	enum
	{
		arg_id = 1,
		arg_weaponid,
		arg_skin_index
	};

	new id = get_param(arg_id);
	new weaponid = get_param(arg_weaponid);
	new skin_index = get_param(arg_skin_index);

	if(id < 1 || id > 32)
	{
		log_error(AMX_ERR_NATIVE, "[WSS] Set user skin: wrong player index! index %d", id);
		return 0;
	}

	if(!weaponid)
	{
		arrayset(g_iPlayerSkins[id], 0, sizeof(g_iPlayerSkins[]));
		return 1;
	}

	g_iPlayerSkins[id][weaponid] = skin_index;

	return 1;
}

public client_connect(id)
{
	arrayset(g_iPlayerSkins[id], 0, sizeof(g_iPlayerSkins[]));
}

#if defined DEFAULT_SKIN_MENU
public Command_ChangeSkin(id)
{
	new menu = menu_create("Skin Menu", "SkinMenu_Handler");

	new skin_info[SkinInfo];
	for(new i; i < g_iWeaponSkinsCount; i++)
	{
		ArrayGetArray(g_aWeaponSkins, i, skin_info);
		menu_additem(menu, skin_info[SkinName]);
	}
	menu_display(id, menu);
}
public SkinMenu_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new skin_info[SkinInfo];
	ArrayGetArray(g_aWeaponSkins, item, skin_info);

	g_iPlayerSkins[id][skin_info[WeaponID]] = item + 1;
	
	new weapon, weaponid;
	new cur_weapon = get_pdata_cbase(id, m_pActiveItem, XO_CBASEPLAYER);

	#define MAX_ITEM_SLOTS 6

	for(new i; i < MAX_ITEM_SLOTS; i++)
	{
		weapon = get_pdata_cbase(id, m_rgpPlayerItems_CBasePlayer + i, XO_CBASEPLAYER);

		while (is_valid_pev(weapon))
		{
			weaponid = get_pdata_int(weapon, m_iId, XO_CBASEPLAYERWEAPON);

			if(weaponid == skin_info[WeaponID])
			{
				set_weapon_skin(weapon, item + 1);

				if(weapon == cur_weapon)
				{
					if(skin_info[ModelV]) set_pev(id, pev_viewmodel, skin_info[ModelV]);
					if(skin_info[ModelP]) set_pev(id, pev_weaponmodel, skin_info[ModelP]);
				}
				// stop cycles
				i = 6; break;
			}

			weapon = get_pdata_cbase(weapon, m_pNext, XO_CBASEPLAYERWEAPON);
		}
	}

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public Command_ResetSkin(id)
{
	static weapons[][] = 
	{
		"", "weapon_p228", "weapon_shield", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4",
		"weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45",
		"weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy",
		"weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle",
		"weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90"
	};

	new menu = menu_create("Skin Reset", "SkinReset_Handler");

	for(new i = 1, num[2]; i < 32; i++)
	{
		if(g_LoadedWeapons & (1 << i) && g_iPlayerSkins[id][i])
		{
			num[0] = i;
			menu_additem(menu, weapons[i], num);
		}
	}

	menu_display(id, menu);
}

public SkinReset_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new info[2], buffer;
	menu_item_getinfo(menu, item, buffer, info, charsmax(info), .callback = buffer);

	new weaponid = info[0];

	g_iPlayerSkins[id][weaponid] = 0;

	menu_destroy(menu);
	return PLUGIN_HANDLED;
}
#endif // DEFAULT_SKIN_MENU

public cs_weapon_add_to_player(id, weapon, weaponid, type)
{
	if(type == ADD_BY_ARMORY_ENTITY || type == ADD_BY_WEAPONBOX) return 0;

	if(get_weapon_skin(weapon)) return 0;

	if(g_iPlayerSkins[id][weaponid])
	{
		set_weapon_skin(weapon, g_iPlayerSkins[id][weaponid]);
	}

	return 0;
}

public cs_weapon_deploy(id, weapon, weaponid)
{
	new skin = get_weapon_skin(weapon);
	if(skin)
	{
		new skin_info[SkinInfo];
		ArrayGetArray(g_aWeaponSkins, skin - 1, skin_info);
		if(skin_info[ModelV]) set_pev(id, pev_viewmodel, skin_info[ModelV]);
		if(skin_info[ModelP]) set_pev(id, pev_weaponmodel, skin_info[ModelP]);
	}
}

public cs_weapon_drop(id, weaponbox, weapon, weaponid)
{
	new skin = get_weapon_skin(weapon);
	if(skin)
	{
		new skin_info[SkinInfo];
		ArrayGetArray(g_aWeaponSkins, skin - 1, skin_info);
		engfunc(EngFunc_SetModel, weaponbox, skin_info[ModelW]);
		return 1;
	}
	return 0;
}

stock get_weapon_csw(weapon_name[])
{
	static weapons[][] = 
	{
		"", "weapon_p228", "weapon_shield", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4",
		"weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45",
		"weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy",
		"weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle",
		"weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90"
	};

	for(new i = 1; i < sizeof(weapons); i++)
	{
		if(equali(weapon_name, weapons[i]))
		{
			return i;
		}
	}

	return 0;
}
