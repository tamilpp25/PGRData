---@class XUiPanelDlcBoss : XUiNode
local XUiPanelDlcBoss = XClass(XUiNode, "XUiPanelDlcBoss")

function XUiPanelDlcBoss:OnEnable()
    self:ShowPanel()
end

function XUiPanelDlcBoss:ShowPanel()
    local worldId = XFightUtil.GetDlcHuntWorldId()
    local detailList = XDlcHuntWorldConfig.GetWorldBossDetailOnPause(worldId)
    for i = 1, #detailList do
        local detail = detailList[i]
        local uiName = CS.UnityEngine.Object.Instantiate(self.TxtSkillName, self.TxtSkillName.transform.parent)
        local uiDesc = CS.UnityEngine.Object.Instantiate(self.TxtSkillbrief, self.TxtSkillbrief.transform.parent)
        uiName.text = detail.Name
        uiDesc.text = detail.Desc
    end
    self.TxtSkillName.gameObject:SetActive(false)
    self.TxtSkillbrief.gameObject:SetActive(false)
end

function XUiPanelDlcBoss:CheckDataIsChange()
    return false
end

return XUiPanelDlcBoss
