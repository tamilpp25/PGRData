local XUiGridPairGroup = XClass(nil,"XUiGridPairGroup")

function XUiGridPairGroup:Ctor(ui,playerId,index)
    ---@type UnityEngine.GameObject
    self.GameObject = ui
    self.Transform = self.GameObject.transform
    self.GroupId = XMoeWarConfig.GetPlayerGroup(playerId)
    self.PlayerId = playerId
    self.Index = index
    XTool.InitUiObject(self)
    CS.XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self:PlaySwitchAnimation()
        self:InitUiView()
    end,((self.GroupId - 1) * 4 + index) * 80)
end

function XUiGridPairGroup:InitUiView()
    local leftPlayer = XDataCenter.MoeWarManager.GetPlayer(self.PlayerId)
    --local rightPlayer = XDataCenter.MoeWarManager.GetPlayer(self.Config.PlayerId[2])
    self.ImgLeftHead:SetRawImage(leftPlayer:GetCircleHead())
    --self.ImgRightHead:SetRawImage(rightPlayer:GetCircleHead())
    self.TxtLeftName.text = leftPlayer:GetName()
    --self.TxtRightName.text = rightPlayer:GetName()
    self.BtnGroup.CallBack = function()
        self:OnClickBtnGroup()
    end
end

function XUiGridPairGroup:OnClickBtnGroup()
	local key = string.format("%s_%s","MOE_WAR_VOTE_SHOW_MATCH_SCENE",tostring(XPlayer.Id))
	XSaveTool.SaveData(key,true)
	local defaultSelectKey = string.format("%s_%s",XMoeWarConfig.DEFAULT_SELECT_KEY_PREFIX,tostring(XPlayer.Id))
	XSaveTool.SaveData(defaultSelectKey,self:CalculatePairId())
    XLuaUiManager.Open("UiMoeWarVote",self:CalculatePairId())
end

function XUiGridPairGroup:CalculatePairId()
    return (self.GroupId - 1) * 9 + self.Index
end

function XUiGridPairGroup:PlaySwitchAnimation()
	if self.AniRole1 then
		self.AniRole1.gameObject:SetActiveEx(true)
		--self.AniRole2.gameObject:SetActiveEx(true)
		self.PlayableDirector:Play()
	end
end

return XUiGridPairGroup