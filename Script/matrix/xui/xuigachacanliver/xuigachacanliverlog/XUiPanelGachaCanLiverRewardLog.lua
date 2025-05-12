local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiPanelGachaCanLiverRewardLog: XUiNode
---@field _Control XGachaCanLiverControl
---@field RootUi XLuaUi
local XUiPanelGachaCanLiverRewardLog = XClass(XUiNode, 'XUiPanelGachaCanLiverRewardLog')

function XUiPanelGachaCanLiverRewardLog:OnStart(rootUi)
    self.RootUi = rootUi
    self.GridItem.gameObject:SetActiveEx(false)
    self:InitUiShow()
end

function XUiPanelGachaCanLiverRewardLog:InitUiShow()
    -- gacha通用预制已经有特殊和普通两个大分区了，隐藏其他小分区标题
    -- 逻辑基于通用预制特殊处理
    for i = 1, 10 do
        local titleObj = self['Title'..i]
        
        if i ~= 4 and i ~= 1 then
            local parent = self["PanelItem"..i]
            if parent then
                parent.gameObject:SetActiveEx(false)
            end
        end
        
        if titleObj then
            titleObj.gameObject:SetActiveEx(i == 4)
        else
            -- 要求分区后缀连续，为空表示结束
            break
        end
    end
end

function XUiPanelGachaCanLiverRewardLog:RefreshUiShow(gachaConfig)
    if self.GachaConfig then
        return
    end

    self.GachaConfig = gachaConfig
    local rewardRareLevelList = XDataCenter.GachaManager.GetGachaRewardSplitByRareType(gachaConfig.Id)
    -- 生成奖励格子
    -- UI预制的特殊分区格子索引为1，普通分区的索引为4. 如果后面通用预制有调整，这里的逻辑也需要调整
    -- 如果换成独立的预制，那么Ui结构和逻辑都应当优化一下
    for i, group in pairs(rewardRareLevelList) do
        local index = i == 1 and 1 or 4
        local parent = self["PanelItem"..index]
        for _, v in pairs(group) do
            local go = CS.UnityEngine.Object.Instantiate(self.GridItem, parent)
            go.gameObject:SetActiveEx(true)
            local item = XUiGridCommon.New(self.RootUi, go)

            local tmpData = {}
            tmpData.TemplateId = v.TemplateId
            tmpData.Count = v.Count
            
            local curCount
            if v.RewardType == XGachaConfigs.RewardType.Count then
                curCount = v.CurCount
            end
            item:Refresh(tmpData, nil, nil, nil, curCount)

            -- 自定义品质
            if XTool.IsNumberValid(v.Id) then
                local cfg = XGachaConfigs.GetGachaReward()[v.Id]

                if cfg and not string.IsNilOrEmpty(cfg.Note) then
                    local quality = string.IsNumeric(cfg.Note) and tonumber(cfg.Note) or nil

                    if XTool.IsNumberValid(quality) then
                        item:SetQualityShowCustom(quality)
                    end
                end
            end
        end
    end
end


return XUiPanelGachaCanLiverRewardLog