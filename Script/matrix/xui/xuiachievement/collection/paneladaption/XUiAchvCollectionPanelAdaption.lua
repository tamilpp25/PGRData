--================
--收藏品页面筛选与藏品获得数面板
--================
local XUiAchvCollectionPanelAdaption = {}

local TempPanel

local function InitDropDown(uiAchvCollect)
    if not TempPanel.BtnSort then return end
    if uiAchvCollect.CurScreenType then return end
    local Dropdown = CS.UnityEngine.UI.Dropdown
    local dropDown = TempPanel.BtnSort
    local screenTagList = XMedalConfigs.GetScoreScreenTagConfigs()
    dropDown:ClearOptions()
    dropDown.captionText.text = CS.XTextManager.GetText("ScreenAll")
    local firstOp = Dropdown.OptionData()
    firstOp.text = CS.XTextManager.GetText("ScreenAll")
    dropDown.options:Add(firstOp)
    for _,v in pairs(screenTagList) do
        local op = Dropdown.OptionData()
        op.text = v.Name or ""
        dropDown.options:Add(op)
    end
    dropDown.value = 0
    dropDown.onValueChanged:AddListener(function(value)
            uiAchvCollect.CurScreenType = value
            uiAchvCollect:Filter(value)
        end)
    uiAchvCollect:Filter(0)
end

local function RefreshGetCount()
    if not TempPanel then return end
    if TempPanel.TxtCollectionGetCount then
        local allCfgs = XMedalConfigs.GetScoreTitlesConfigs()
        local getCount = 0
        local groupDic = {}
        for id, _ in pairs(allCfgs) do
            local scoreTitle = XDataCenter.MedalManager.GetScoreTitleById(id)
            if ((not scoreTitle.IsLock)) then
                if scoreTitle.GroupId > 0 then
                    if not groupDic[scoreTitle.GroupId] then
                        groupDic[scoreTitle.GroupId] = true
                        getCount = getCount + 1
                    end
                else
                    getCount = getCount + 1
                end
            end
        end
        TempPanel.TxtCollectionGetCount.text = getCount
    end
end

local function Clear()
    TempPanel = nil
end

XUiAchvCollectionPanelAdaption.OnEnable = function(uiAchvCollect)
    TempPanel = {}
    XTool.InitUiObjectByUi(TempPanel, uiAchvCollect.PanelAdaption)
    InitDropDown(uiAchvCollect)
    RefreshGetCount()
end

XUiAchvCollectionPanelAdaption.OnDisable = function()
    Clear()
end

XUiAchvCollectionPanelAdaption.OnDestroy = function()
    Clear()
end

return XUiAchvCollectionPanelAdaption