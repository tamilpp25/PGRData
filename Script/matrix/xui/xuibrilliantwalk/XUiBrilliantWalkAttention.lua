--显示注意事项
local XUiBrilliantWalkAttention = XLuaUiManager.Register(XLuaUi, "UiBrilliantWalkAttention")

function XUiBrilliantWalkAttention:OnAwake()
    self.PanelTxt.gameObject:SetActiveEx(false)
    self.BtnTanchuangClose.CallBack = function()
        self:OnBtnClose()
    end
    self.BtnClose.CallBack = function()
        self:OnBtnClose()
    end
    self.GameObjectList = {}

    self.GameObjectPool = XStack.New() --PerkGridUI内存池
    self.GameObjectList = XStack.New() --正在使用的PerkGridUI
    self.PanelTxt.gameObject:SetActiveEx(false) --PerkGridUI template
end

function XUiBrilliantWalkAttention:OnEnable(openUIData)
    self.StageId = openUIData.StageId
    self:UpdateView()
end

function XUiBrilliantWalkAttention:UpdateView()
    local configs = XBrilliantWalkConfigs.GetAttentionConfig(self.StageId)
    self:GameObjectReturnPool()
    for index, _ in ipairs(configs.Title) do
        local tmpObj = self:GetGameObject()
        tmpObj.TxtRuleTittle.text = configs.Title[index]
        tmpObj.TxtRule.text = configs.Content[index]
        tmpObj.GameObject:SetActiveEx(true)
        table.insert(self.GameObjectList,tmpObj)
    end
end


function XUiBrilliantWalkAttention:GetGameObject()
    local item
    if self.GameObjectPool:IsEmpty() then
        local go = CS.UnityEngine.Object.Instantiate(self.PanelTxt, self.PanelContent)
        local tmpObj = {}
        tmpObj.Transform = go.transform
        tmpObj.GameObject = go.gameObject
        XTool.InitUiObject(tmpObj)
        item = tmpObj
    else
        item = self.GameObjectPool:Pop()
    end
    item.GameObject:SetActiveEx(true)
    self.GameObjectList:Push(item)
    return item
end

function XUiBrilliantWalkAttention:GameObjectReturnPool()
    while (not self.GameObjectList:IsEmpty()) do
        local object = self.GameObjectList:Pop()
        object.GameObject:SetActiveEx(false)
        self.GameObjectPool:Push(object)
    end
end

function XUiBrilliantWalkAttention:OnBtnClose()
    self.ParentUi:CloseMiniSubUI("UiBrilliantWalkAttention")
end