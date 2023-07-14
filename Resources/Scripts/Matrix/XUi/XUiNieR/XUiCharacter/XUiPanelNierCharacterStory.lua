local XUiPanelNierCharacterStory = XClass(nil, "XUiPanelNierCharacterStory")
local XUiGrideNieRCharacterStory = require("XUi/XUiNieR/XUiCharacter/XUiGrideNieRCharacterStory")

function XUiPanelNierCharacterStory:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = parent

    XTool.InitUiObject(self)
    
    self.DynamicTable = XDynamicTableNormal.New(self.PanelTaskStoryList)
    self.DynamicTable:SetProxy(XUiGrideNieRCharacterStory)
    self.DynamicTable:SetDelegate(self)

end

function XUiPanelNierCharacterStory:ShowPanel(isPlayAnimation)
    self.IsPlayAnimation = isPlayAnimation
    self.GameObject:SetActive(true)
end

function XUiPanelNierCharacterStory:HidePanel()
    self.IsPlayAnimation = false
    self.GameObject:SetActive(false)
end

function XUiPanelNierCharacterStory:InitAllInfo()
    self:UpdateAllInfo()
end

function XUiPanelNierCharacterStory:UpdateAllInfo()
    local characterData = XDataCenter.NieRManager.GetSelNieRCharacter()
    local characterId = characterData:GetNieRCharacterId()
    local inforList = XNieRConfigs.GetNieRCharacterInforListById(characterId)
    self.DataList = {}
    for _, config in ipairs(inforList) do
        local condit, desc 
        if config.UnlockCondition ~= 0 then
            condit, desc  = XConditionManager.CheckCondition(config.UnlockCondition)
        else
            condit, desc = true, ""
        end
        local tmpInfor = {}
        tmpInfor.Config = config
        tmpInfor.Desc = desc     
        
        if condit then
            if not XDataCenter.NieRManager.CheckCharacterInformationUnlock(config.Id, false) then
                tmpInfor.IsUnLock = XNieRConfigs.NieRChInforStatue.CanUnLock
            else
                tmpInfor.IsUnLock = XNieRConfigs.NieRChInforStatue.UnLock
            end
        else
            tmpInfor.IsUnLock = XNieRConfigs.NieRChInforStatue.Lock
        end
        table.insert(self.DataList, tmpInfor)
    end

    -- table.sort(self.DataList, function(a, b)
    --     if a.IsUnLock > b.IsUnLock then
    --         return true
    --     elseif a.IsUnLock == b.IsUnLock then
    --         return a.Config.Priority < b.Config.Priority
    --     end
    --     return false
    -- end)

    self.DynamicTable:SetDataSource(self.DataList)
    self.DynamicTable:ReloadDataASync()
end

function XUiPanelNierCharacterStory:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.DataList[index])
    end
end

return XUiPanelNierCharacterStory