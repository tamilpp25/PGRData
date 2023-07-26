--肉鸽2.0羁绊组合详细页面：页签控件
local XUiBiancaTheatreComboTipsTab = XClass(nil, "XUiBiancaTheatreComboTipsTab")
local UiButtonState = CS.UiButtonState
function XUiBiancaTheatreComboTipsTab:Ctor(ui, rootUi, index, tabData, isShowDisplay, onClickCallBack)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.RootUi = rootUi
    self.Button = self.GameObject:GetComponent("XUiButton")
    local combo = tabData.Combo
    
    if tabData.TabType ~= "BtnFirst" then
        self.BtnType = XBiancaTheatreConfigs.ComboBtnType.ChildComboType
        self.Button:ShowTag(tabData.IsActive)      
        self.Button:SetNameByGroup(0, tabData.Name)

        --已激活的阶段标记
        local phaseLevel = combo:GetPhaseLevel()
        local isShowTag = not isShowDisplay and XTool.IsNumberValid(phaseLevel)
        self.Button:SetNameByGroup(1, CS.XTextManager.GetText("ExpeditionComboTipsPhaseTitle", phaseLevel))
        if self.labelNormal then
            self.labelNormal.gameObject:SetActiveEx(isShowTag)
        end
        if self.labelPress then
            self.labelPress.gameObject:SetActiveEx(isShowTag)
        end
        if self.labelSelect then
            self.labelSelect.gameObject:SetActiveEx(isShowTag)
        end
    else
        self.BtnType = XBiancaTheatreConfigs.ComboBtnType.BaseComboType
        local isAdventure = XDataCenter.BiancaTheatreManager.CheckHasAdventure()
        local name = (isAdventure and not isShowDisplay) and 
                tabData.Name .. string.format(" %d/%d", tabData.ActiveChildCount, tabData.ChildCount) 
                or tabData.Name
        self.Button:SetNameByGroup(0, name)
    end
    if self.BtnType == XBiancaTheatreConfigs.ComboBtnType.ChildComboType then
        self.ECombo = combo
    end
    self.OnClickCallBack = onClickCallBack
    self.Index = index
end

function XUiBiancaTheatreComboTipsTab:OnClick()
    if self.BtnType == XBiancaTheatreConfigs.ComboBtnType.ChildComboType then
        self.RootUi:PlayAnimation("QieHuan")
        self:RefreshComboList()
    end
end

function XUiBiancaTheatreComboTipsTab:RefreshComboList()
    self.RootUi:RefreshComboList(self.ECombo)
end

return XUiBiancaTheatreComboTipsTab