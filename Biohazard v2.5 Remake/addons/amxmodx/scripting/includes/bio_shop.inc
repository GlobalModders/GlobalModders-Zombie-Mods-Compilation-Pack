#define TEAM_ZOMBIE 1
#define TEAM_HUMAN 2

// Natives
native bio_register_item(const item_name[], const item_cost, const item_desc[], const item_team)
native bio_open_shop(id)

// Forwards
forward bio_item_selected(id, item)