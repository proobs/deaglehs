public void OpenRoundVoteMenu(int client) {
	Menu roundvote = new Menu(roundvote_handler);
	roundvote.SetTitle("RoundVote menu!");
	
	if(g_cvHighFovRound.BoolValue)
		roundvote.AddItem("0", "High-Fov Round");
	
	if(g_cvLowFovRound.BoolValue)
		roundvote.AddItem("1", "Low-Fov Round");
	
	if(g_cvZeusRound.BoolValue)
		roundvote.AddItem("2", "35 HP Zeus & Knife Round");
	
	if(g_cvRevolverRound.BoolValue)
		roundvote.AddItem("3", "Revolver Round");

	roundvote.ExitButton = true;
	roundvote.Display(MENU_TIME_FOREVER, client);
}

public int roundvote_handler(Menu menu, MenuAction action, int param1, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			PrintToChatAll("%s A round vote has been called by %N", PREFIX, param1);

			if(StrEqual(item, "0")) {
				StartHighFovVote();
			} else if(StrEqual(item, "1")) {
				StartLowFovVote();
			} else if(StrEqual(item, "2")) {
				StartZeusVote();
			} else if(StrEqual(item, "3")) {
				StartRevolverVote();
			}
		}
		case MenuAction_End: {
			delete menu; 
		}
	}
}

// Vote Menus

public void StartVote(Menu menu) {
	menu.AddItem("no", "No");
	menu.DisplayVoteToAll(30);
	menu.ExitButton = false;
}

public void StartHighFovVote() {
	Menu menu = new Menu(vote_handler);
	menu.SetTitle("High FOV Round?");
	menu.AddItem("0", "Yes");	
	StartVote(menu);
	
	g_iRoundType = ROUNDTYPE_HIGHFOV;
}

public void StartLowFovVote() {
	Menu menu = new Menu(vote_handler);
	menu.SetTitle("Low FOV Round?");
	menu.AddItem("0", "Yes");
	StartVote(menu);
	
	g_iRoundType = ROUNDTYPE_LOWFOV;
}

public void StartZeusVote() {
	Menu menu = new Menu(vote_handler);
	menu.SetTitle("35 HP Zeus/Knife Round?");
	menu.AddItem("0", "Yes");
	StartVote(menu);
	
	g_iRoundType = ROUNDTYPE_ZEUS;
}

public void StartRevolverVote() {
	Menu menu = new Menu(vote_handler);
	menu.SetTitle("Revolver HS Only Round?");
	menu.AddItem("0", "Yes");
	StartVote(menu);
	
	g_iRoundType = ROUNDTYPE_REVOLVER; 
}

//vote menu handlers
public int vote_handler(Menu menu, MenuAction action, int param1, int param2) {
	switch(action) {
		case MenuAction_VoteEnd: {
			char item[PLATFORM_MAX_PATH], display[64];
			float percent;
			int votes, totalVotes;

			GetMenuVoteInfo(param2, votes, totalVotes);
			menu.GetItem(param1, item, sizeof(item), _, display, sizeof(display));
			
			percent = float(votes) / float(totalVotes);
			
			if(percent >= g_cvVotePercentage.FloatValue) {
				switch(g_iRoundType) {
					case ROUNDTYPE_HIGHFOV: {
						PrintToChatAll("%s High FOV Round vote passed! Enabling next round...", PREFIX);
					} case ROUNDTYPE_LOWFOV: {
						PrintToChatAll("%s High FOV Round vote passed! Enabling next round...", PREFIX);
					} case ROUNDTYPE_ZEUS: {
						PrintToChatAll("%s High FOV Round vote passed! Enabling next round...", PREFIX);
					} case ROUNDTYPE_REVOLVER: {
						PrintToChatAll("%s High FOV Round vote passed! Enabling next round...", PREFIX);
					}
				}
				Call_StartForward(g_hOnRoundVotePre);
			} else {
				PrintToChatAll("%s Vote Failed...", PREFIX);
				g_iRoundType = ROUNDTYPE_NONE;
			}
			
			g_iCoolDown = g_cvRoundVoteCoolDown.IntValue;
			
		} case MenuAction_End: {
			delete menu; 
		}
	}
}

// rounds

public void HighFovRound() {
	for (int i = 1; i <= MaxClients; i++) {
		SetEntProp(i, Prop_Send, "m_iFOV", g_cvHighFovValue.IntValue);
	}
}

public void LowFovRound() {
	for (int i = 1; i <= MaxClients; i++) {
		SetEntProp(i, Prop_Send, "m_iFOV", g_cvLowFovValue.IntValue);
		GiveDeagle(i);
	}
}

public void RevolverRound() {
	for (int i = 1; i <= MaxClients; i++) {
		StripWeapons(i);
		GivePlayerItem(i, "weapon_revolver");
	}
}

public void ZeusRound() {
	for (int i = 1; i <= MaxClients; i++) {
		StripWeapons(i);
		GivePlayerItem(i, "weapon_taser");
	}
}

public void ResetFov() {
	for (int i = 1; i <= MaxClients; i++) {
		SetEntProp(i, Prop_Send, "m_iFOV", 90);
	}
}