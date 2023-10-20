local XUiBattleRoleRoomCaptain = XLuaUiManager.Register(XLuaUi, "UiBattleRoleRoomCaptain")

-- 最多只记录10次
local MaxChangeTimes = 10

function XUiBattleRoleRoomCaptain:OnAwake()
    -- 重定义 begin
    self.RImgIcon1 = self.RawImage01
    self.RImgIcon2 = self.RawImage02
    self.RImgIcon3 = self.RawImage03
    self.TxtName1 = self.TextName01
    self.TxtName2 = self.TextName02
    self.TxtName3 = self.TextName03
    self.TxtSkillName1 = self.TextJinengName01
    self.TxtSkillName2 = self.TextJinengName02
    self.TxtSkillName3 = self.TextJinengName03
    self.TxtSkillDesc1 = self.TextJinengInfo01
    self.TxtSkillDesc2 = self.TextJinengInfo02
    self.TxtSkillDesc3 = self.TextJinengInfo03
    self.CaptainBtnGroup = self.PanelBtnSel
    self.BtnSelect1 = self.BtnSel01
    self.BtnSelect2 = self.BtnSel02
    self.BtnSelect3 = self.BtnSel03
    self.PanelEnable1 = self.Ena01
    self.PanelEnable2 = self.Ena02
    self.PanelEnable3 = self.Ena03
    self.PanelDisable1 = self.Dis01
    self.PanelDisable2 = self.Dis02
    self.PanelDisable3 = self.Dis03
    -- 重定义 end
    self.CharacterViewModelDic = nil
    self.Callback = nil
    -- 当前队长位置
    self.CurrentCaptainPos = nil
    self.ChangeTimes = 0
    self:RegisterUiEvents()
end

-- team : XTeam
function XUiBattleRoleRoomCaptain:OnStart(characterViewModelDic, currentCaptainPos, callback)
    self.CharacterViewModelDic = characterViewModelDic
    self.CurrentCaptainPos = currentCaptainPos
    self.Callback = callback
    -- 刷新数据
    self:RefreshRoleList()
    self.CaptainBtnGroup:SelectIndex(currentCaptainPos)
end

--######################## 私有方法 ########################

function XUiBattleRoleRoomCaptain:RegisterUiEvents()
    self.BtnTanchuangCloseBig.CallBack = function() self:OnCloseClicked() end
    self.CaptainBtnGroup:Init({
        self.BtnSelect1,
        self.BtnSelect2,
        self.BtnSelect3,
    }, function(tabIndex) 
        self:OnCaptainBtnGroupClicked(tabIndex) 
    end)
end

function XUiBattleRoleRoomCaptain:OnCaptainBtnGroupClicked(index)
    -- 禁用中，不处理
    if self["BtnSelect" .. index].ButtonState == CS.UiButtonState.Disable then
        return
    end
    self.ChangeTimes = math.min(MaxChangeTimes, self.ChangeTimes + 1)
    self.CurrentCaptainPos = index
end

function XUiBattleRoleRoomCaptain:OnCloseClicked()
    local viewModel = self.CharacterViewModelDic[self.CurrentCaptainPos]
    if viewModel and self.ChangeTimes > 1 then
        local id = viewModel:GetId()
        if XRobotManager.CheckIsRobotId(id) then
            id = XRobotManager.GetCharacterId(id)
        end

        XMVCA.XFavorability:PlayCvByType(id, XEnumConst.Favorability.SoundEventType.CaptainJoinTeam)
    end
    if self.Callback then self.Callback(self.CurrentCaptainPos) end
    self:Close()
end

function XUiBattleRoleRoomCaptain:RefreshRoleList()
    local viewModel = nil
    local captainSkillInfo = nil 
    local skillDesc = nil
    for pos = 1, 3 do
        viewModel = self.CharacterViewModelDic[pos]
        if viewModel then
            captainSkillInfo = viewModel:GetCaptainSkillInfo()
            self["RImgIcon" .. pos]:SetRawImage(viewModel:GetSmallHeadIcon())
            self["TxtName" .. pos].text = viewModel:GetLogName()
            self["TxtSkillName" .. pos].text = captainSkillInfo.Name
            skillDesc = captainSkillInfo.Intro
            if captainSkillInfo.Level <= 0 then
                skillDesc = skillDesc .. XUiHelper.GetText("CaptainSkillLock")
            end
            self["TxtSkillDesc" .. pos].text = skillDesc
            self["PanelEnable" .. pos].gameObject:SetActiveEx(true)
            self["PanelDisable" .. pos].gameObject:SetActiveEx(false)
            self["BtnSelect" .. pos]:SetButtonState(CS.UiButtonState.Normal)
        else
            self["PanelEnable" .. pos].gameObject:SetActiveEx(false)
            self["PanelDisable" .. pos].gameObject:SetActiveEx(true)
            self["BtnSelect" .. pos]:SetButtonState(CS.UiButtonState.Disable)
        end
    end    
end

function XUiBattleRoleRoomCaptain:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.Remove, self)
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.Remove, self)
end

function XUiBattleRoleRoomCaptain:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_BEGIN_PLAYMOVIE, self.Remove, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_LOADINGFINISHED, self.Remove, self)
end

return XUiBattleRoleRoomCaptain