---@class XUiPanelScheduleCommonPair
local XUiPanelScheduleCommonPair = XClass(nil, "XUiPanelScheduleCommonPair")

---@param transform UnityEngine.RectTransform
function XUiPanelScheduleCommonPair:Ctor(transform, isShowModel, index, showModelFunc)
    self.Transform = transform
    self.GameObject = transform.gameObject
    self.RoleDic = {}
    self.Index = index
    self.IsShowModel = isShowModel
    self.ShowModelFunc = showModelFunc
    XTool.InitUiObject(self)
    if self.BtnPlayBack then
        self.BtnPlayBack.CallBack = function()
            XDataCenter.MoeWarManager.EnterAnimation(self.PairInfo, self.Match)
        end
    end
    self.PanelWenhao = self.GameObject:FindTransform("PanelWenhao")
    self.PanelWin = self.GameObject:FindTransform("PanelWin")
end

---@param match XMoeWarMatch
function XUiPanelScheduleCommonPair:Refresh(pairInfo, match)
    self.Match = match
    if self.BtnPlayBack then
        self.BtnPlayBack.gameObject:SetActiveEx(match:GetResultOut())
    end
    self.PairInfo = pairInfo
    ---刷新下面的1-3个头像
    for i, playerId in pairs(pairInfo.Players) do
        if not self.RoleDic[i] then
            ---@type UnityEngine.RectTransform
            local rolePanel = self["PanelRole" .. i]
            self.RoleDic[i] = self:InitRoleUi(rolePanel)
        end
        ---@type XMoeWarPlayer
        local playerEntity = XDataCenter.MoeWarManager.GetPlayer(playerId)
        local role = self.RoleDic[i]
        role.HeadIcon:SetRawImage(playerEntity:GetCircleHead())
        role.TxtName.text = playerEntity:GetName()
        role.TxtNum.text = playerEntity:GetSupportCount(match.Id)
        role.RImgIcon:SetRawImage(CS.XGame.ClientConfig:GetString("MoeWarScheduleSupportIcon"))
        if self.PanelWin then
            self.PanelWin.gameObject:SetActiveEx(match:GetType() == XMoeWarConfig.MatchType.Publicity)
        end
        if self.PanelWenhao then
            self.PanelWenhao.gameObject:SetActiveEx(match:GetType() ~= XMoeWarConfig.MatchType.Publicity and (match:GetSessionId() == XMoeWarConfig.SessionType.Game3In1 or match:GetSessionId() == XMoeWarConfig.SessionType.Game6In3))
        end
        local line = self.Transform:Find("Line" .. i)
        local winLine = self.Transform:Find("LineWin/PanelWin")
        if winLine then
            winLine.gameObject:SetActiveEx(match:GetType() == XMoeWarConfig.MatchType.Publicity)
        end
        local rankIcon = self["PanelRole" .. i]:Find("RawImage")
        if rankIcon then
            rankIcon.gameObject:SetActiveEx(match:GetType() == XMoeWarConfig.MatchType.Publicity)
            local rImgIcon = rankIcon:GetComponent("RawImage")
            if pairInfo.WinnerId == playerId then
                rImgIcon:SetRawImage(XMoeWarConfig.ScheduleIcon[1])
            elseif pairInfo.SecondId == playerId then
                rImgIcon:SetRawImage(XMoeWarConfig.ScheduleIcon[2])
            else
                rImgIcon:SetRawImage(XMoeWarConfig.ScheduleIcon[3])
            end
        end
        if match:GetType() == XMoeWarConfig.MatchType.Publicity then
            if pairInfo.WinnerId and pairInfo.WinnerId > 0 and playerId == pairInfo.WinnerId then
                role.PanelLose.gameObject:SetActiveEx(false)
                role.PanelWenhao.gameObject:SetActiveEx(false)
                if line then
                    line:Find("PanelWin").gameObject:SetActiveEx(true)
                end
            elseif pairInfo.WinnerId and pairInfo.WinnerId > 0 and playerId ~= pairInfo.WinnerId then
                role.PanelLose.gameObject:SetActiveEx(true)
                if line then
                    line:Find("PanelWin").gameObject:SetActiveEx(false)
                end
            elseif pairInfo.WarSituation == XMoeWarConfig.WarSituationType.WeedOut then
                role.PanelLose.gameObject:SetActiveEx(true)
            end
        end
    end
    ---刷新晋级的头像
    if match:GetType() == XMoeWarConfig.MatchType.Publicity and self.PanelRoleWin then
        if not self.RoleWin then
            self.RoleWin = self:InitRoleUi(self.PanelRoleWin)
        end
        ---@type XMoeWarPlayer
        local winPlayer = XDataCenter.MoeWarManager.GetPlayer(pairInfo.WinnerId)
        self.RoleWin.HeadIcon:SetRawImage(winPlayer:GetCircleHead())
        self.RoleWin.TxtName.text = winPlayer:GetName()
        self.RoleWin.TxtNum.text = winPlayer:GetSupportCount(match.Id)
        self.RoleWin.RImgIcon.gameObject:SetActiveEx(true)
        self.RoleWin.RImgIcon:SetRawImage(CS.XGame.ClientConfig:GetString("MoeWarScheduleSupportIcon"))
        self.RoleWin.PanelWenhao.gameObject:SetActiveEx(false)

        ---todo 刷新模型
        if self.IsShowModel and self.ShowModelFunc then
            if match:GetSessionId() == XMoeWarConfig.SessionType.Game3In1 or match:GetSessionId() == XMoeWarConfig.SessionType.FailWeekVotingDown then
                self.ShowModelFunc(nil, winPlayer)
            else
                self.ShowModelFunc(self.Index, winPlayer)
            end
        end
    elseif match:GetType() == XMoeWarConfig.MatchType.Voting and self.PanelRoleWin then
        if not self.RoleWin then
            self.RoleWin = self:InitRoleUi(self.PanelRoleWin)
        end
        self.RoleWin.PanelWenhao.gameObject:SetActiveEx(true)
        self.RoleWin.TxtName.text = ""
        self.RoleWin.TxtNum.text = ""
        self.RoleWin.PanelLose.gameObject:SetActiveEx(false)
        self.RoleWin.RImgIcon.gameObject:SetActiveEx(false)
    end
end

---@param transform UnityEngine.RectTransform
function XUiPanelScheduleCommonPair:InitRoleUi(transform)
    local obj = {
        HeadIcon = transform:Find("Head/StandIcon"):GetComponent("RawImage"),
        PanelLose = transform:Find("Head/PanelLose"),
        PanelWenhao = transform:Find("Head/PanelWenhao"),
        TxtName = transform:Find("TextName"):GetComponent("Text"),
        TxtNum = transform:Find("PanelRoleNum/TextName"):GetComponent("Text"),
        RImgIcon = transform:Find("PanelRoleNum/RawImage"):GetComponent("RawImage"),
        RankIcon = transform:Find("RawImage")
    }
    return obj
end

return XUiPanelScheduleCommonPair
