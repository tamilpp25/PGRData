local XUiBattleRoleRoomCaptain = XLuaUiManager.Register(XLuaUi, "UiBattleRoleRoomCaptain")

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
    self.CurrentCaptainPos = index
end

function XUiBattleRoleRoomCaptain:OnCloseClicked()
    if self.Callback then self.Callback(self.CurrentCaptainPos) end
    self:Close()
end

function XUiBattleRoleRoomCaptain:RefreshRoleList()
    local viewModel = nil
    local captainSkillInfo = nil 
    for pos = 1, 3 do
        viewModel = self.CharacterViewModelDic[pos]
        if viewModel then
            captainSkillInfo = viewModel:GetCaptainSkillInfo()
            self["RImgIcon" .. pos]:SetRawImage(viewModel:GetSmallHeadIcon())
            self["TxtName" .. pos].text = viewModel:GetLogName()
            self["TxtSkillName" .. pos].text = captainSkillInfo.Name
            self["TxtSkillDesc" .. pos].text = captainSkillInfo.Level > 0 and 
            captainSkillInfo.Intro or CS.XTextManager.GetText("CaptainSkillLock")
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

return XUiBattleRoleRoomCaptain