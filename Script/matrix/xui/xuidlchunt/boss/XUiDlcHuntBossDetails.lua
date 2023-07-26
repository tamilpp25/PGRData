---@class XUiDlcHuntBossDetails:XLuaUi
local XUiDlcHuntBossDetails = XLuaUiManager.Register(XLuaUi, "UiDlcHuntBossDetails")

function XUiDlcHuntBossDetails:Ctor()
    ---@type XDlcHuntWorld
    self._World = false
end

function XUiDlcHuntBossDetails:OnAwake()
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnClickMainUi)
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.Close)
    -- uiDlcHunt hide panelAsset
    self.PanelAsset.gameObject:SetActiveEx(false)
    self.BtnDlcTab.gameObject:SetActiveEx(false)
    self.TxtChapterName = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelLeft/PanelBt/Text", "Text")
end

function XUiDlcHuntBossDetails:OnStart(world)
    self._World = world
    self:Update()
end

function XUiDlcHuntBossDetails:Update()
    local chapter = self:GetChapter()
    self.TxtChapterName.text = chapter:GetName()
    --self.Text.text = chapter:GetName()
    --self.Text2.text = chapter:GetDesc()

    local descList = self:GetPartsCanBreak()
    local buttonList = {}
    for i = 1, #descList do
        local data = descList[i]
        local uiButton = CS.UnityEngine.Object.Instantiate(self.BtnDlcTab, self.BtnDlcTab.transform.parent)
        buttonList[#buttonList + 1] = uiButton
        uiButton:SetNameByGroup(0, data.Name)
        uiButton.gameObject:SetActiveEx(true)
    end

    self.PanelBoss:Init(buttonList, function(index)
        local data = descList[index]
        self.ImgBoss:SetRawImage(data.Icon)
        self.Text.text = data.Name
        self.Text2.text = data.Desc
        self:PlayAnimation("QieHuan")
    end)
    self.PanelBoss:SelectIndex(1)
end

function XUiDlcHuntBossDetails:OnClickMainUi()
    XLuaUiManager.RunMain()
end

function XUiDlcHuntBossDetails:GetChapter()
    local worldId = self._World:GetWorldId()
    local chapterId = XDlcHuntWorldConfig.GetChapterId(worldId)
    if not chapterId then
        XLog.Error("[XViewModelDlcHuntBoss] the world is not belong to any chapter:", tostring(worldId))
        return "???"
    end
    return XDataCenter.DlcHuntManager.GetChapter(chapterId)
end

-- 可破坏部位
function XUiDlcHuntBossDetails:GetPartsCanBreak()
    return XDlcHuntWorldConfig.GetBossPartsCanBreak(self._World)
end

return XUiDlcHuntBossDetails