local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate

local XUiCharSkillOtherParsing = XLuaUiManager.Register(XLuaUi, "UiCharSkillOtherParsing")

function XUiCharSkillOtherParsing:OnAwake()
    self:AutoAddListener()

    self.GridEntry.gameObject:SetActiveEx(false)
end

function XUiCharSkillOtherParsing:OnStart(entryList)
    self.EntryList = entryList
    self.EntryGrids = {}
    self:InitCanvasOrder()
    self:Refresh()
end

function XUiCharSkillOtherParsing:InitCanvasOrder()
    local canvas = self.Transform:GetComponent("Canvas")
    
    local scrollCanvas = self.Transform.parent:FindTransformWithSplit("PaneSkillInfo/PanelScroll"):GetComponent("Canvas")
    scrollCanvas.sortingOrder = canvas.sortingOrder + 1
end

function XUiCharSkillOtherParsing:AutoAddListener()
    self.BtnClose.IsEventPass = true
    self:RegisterClickEvent(self.BtnClose, self.Close)
end

function XUiCharSkillOtherParsing:Refresh()
    for index, entry in ipairs(self.EntryList) do
        local grid = self.EntryGrids[index]
        if not grid then
            local ui = index == 1 and self.GridEntry or CSUnityEngineObjectInstantiate(self.GridEntry, self.PanelEntry)
            grid = XTool.InitUiObjectByUi({}, ui)
            self.EntryGrids[index] = grid
        end

        grid.TxtTitle.text = entry.Name
        grid.TxtDesc.text = entry.Desc

        grid.GameObject:SetActiveEx(true)
    end
    for index = #self.EntryList + 1, #self.EntryGrids do
        self.EntryGrids[index].GameObject:SetActiveEx(false)
    end
end