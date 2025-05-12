--- 涂装选择筛选界面
---@class XUiShopFashionFilter: XLuaUi
local XUiShopFashionFilter = XLuaUiManager.Register(XLuaUi, 'UiShopFashionFilter')

local XUiPanelFilterCareer = require('XUi/XUiShop/UiShopFashionFilter/XUiPanelFilterCareer')
local XUiPanelFilterCharacterList = require('XUi/XUiShop/UiShopFashionFilter/XUiPanelFilterCharacterList')
local XUiPanelFilterElement = require('XUi/XUiShop/UiShopFashionFilter/XUiPanelFilterElement')

function XUiShopFashionFilter:OnAwake()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close)
    self:RegisterClickEvent(self.BtnClose, self.OnCancelFliter)
    self:RegisterClickEvent(self.BtnConfirm, self.OnSubmitFliter)
end

function XUiShopFashionFilter:OnStart(shopId, careerTags, elementTags, characterId, cb)
    self.ShopId = shopId
    self.CallBack = cb
    self:InitTagGroups()
    
    self.PanelFliterCareer = XUiPanelFilterCareer.New(self.PanelCareer, self, self._FliterTagGroupList[CharacterFilterTagTypeNum.Career], careerTags)
    self.PanelFliterElement = XUiPanelFilterElement.New(self.PanelElement, self, self._FliterTagGroupList[CharacterFilterTagTypeNum.Element], elementTags)
    self.PanelFliterCharacterList = XUiPanelFilterCharacterList.New(self.PanelCharacterList, self, characterId)
    
    self.PanelFliterCareer:Open()
    self.PanelFliterElement:Open()
    self.PanelFliterCharacterList:Open()
    
    self:RefreshCharacterListShow()
end

function XUiShopFashionFilter:InitTagGroups()
    -- 拿到该筛选类型要显示的所有标签
    local allTags = XRoomCharFilterTipsConfigs.GetFilterTagCommonGroupTags(CharacterFilterGroupType.FashionShop)
    -- 将标签按组分类
    local allTagGroups = XRoomCharFilterTipsConfigs.GetFilterTagGroup()
    local groupTagDic = {} -- key为CharacterFilterTagGroup.tab对应的group的Id, value = { {TagId = 标签id1, Order = 1}，{TagId = 标签id2, Order = 2} ...}
    for i, tagId in pairs(allTags) do
        local currTagGroupId = nil
        local currTagOrder = 1
        --1.找到该tag的groupId
        for groupId, v in pairs(allTagGroups) do
            local isContainInThisGroup = table.contains(v.Tags, tagId)
            if isContainInThisGroup then
                currTagGroupId = groupId
                currTagOrder = i
            end
        end
        --2.插入字典
        if not groupTagDic[currTagGroupId] then
            groupTagDic[currTagGroupId] = {}
        end
        if currTagGroupId then
            table.insert(groupTagDic[currTagGroupId], {TagId = tagId, Order = currTagOrder})
        end
    end
    
    self._FliterTagGroupList = groupTagDic
end

function XUiShopFashionFilter:RefreshCharacterListShow()
    local careerTags = self.PanelFliterCareer:GetSelectedTags()
    local elementTags = self.PanelFliterElement:GetSelectedTags()
    
    local goodsList = XShopManager.GetShopGoodsList(self.ShopId, true, true)
    
    local characterIds = {}
    local characterMap = {}
    
    -- 获取商品里对应的角色Id
    if not XTool.IsTableEmpty(goodsList) then
        for i, goods in pairs(goodsList) do
            local characterId = XDataCenter.FashionManager.GetCharacterId(goods.RewardGoods.TemplateId)

            if not characterMap[characterId] then
                table.insert(characterIds, characterId)
                characterMap[characterId] = true
            end
        end
    end

    if not XTool.IsTableEmpty(characterIds) then
        -- 剔除非选中职业的角色
        if not XTool.IsTableEmpty(careerTags) then
            for i = #characterIds, 1, -1 do
                local characterId = characterIds[i]
                local charaCareer = XMVCA.XCharacter:GetCharacterCareer(characterId)
                local isSatisfyAnyCareer = false
                for careerTag, _ in pairs(careerTags) do
                    local career = XRoomCharFilterTipsConfigs.GetFilterTagValue(careerTag)
                    if charaCareer == career then
                        isSatisfyAnyCareer = true
                    end
                end

                if not isSatisfyAnyCareer then
                    table.remove(characterIds, i)
                end
            end
        end
        
        -- 剔除非选中元素的角色
        if not XTool.IsTableEmpty(elementTags) then
            for i = #characterIds, 1, -1 do
                local characterId = characterIds[i]
                local charaElement = XMVCA.XCharacter:GetCharacterElement(characterId)
                local isSatisfyAnyElementr = false
                for elementTag, _ in pairs(elementTags) do
                    local element = XRoomCharFilterTipsConfigs.GetFilterTagValue(elementTag)
                    if charaElement == element then
                        isSatisfyAnyElementr = true
                    end
                end

                if not isSatisfyAnyElementr then
                    table.remove(characterIds, i)
                end
            end
        end
    end
    
    table.sort(characterIds, function(a, b) 
        local priorityA = XMVCA.XCharacter:GetCharacterPriority(a)
        local priorityB = XMVCA.XCharacter:GetCharacterPriority(b)

        if priorityA ~= priorityB then
            return priorityA > priorityB
        end
        
        return a > b
    end)
    
    self.PanelFliterCharacterList:RefreshList(characterIds)

    self:RefreshSubmitBtnState()
end

function XUiShopFashionFilter:RefreshSubmitBtnState()
    local characterId = self.PanelFliterCharacterList:GetCurSelectedCharacterId()
    
    self._IsCanSubmit = XTool.IsNumberValid(characterId)

    self.BtnConfirm:SetButtonState(self._IsCanSubmit and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

function XUiShopFashionFilter:OnCancelFliter()
    self:Close()
    if self.CallBack then
        self.CallBack()
    end
end

function XUiShopFashionFilter:OnSubmitFliter()

    if self._IsCanSubmit then
        self:Close()
        if self.CallBack then
            self.CallBack(self.PanelFliterCareer:GetSelectedTags(), self.PanelFliterElement:GetSelectedTags(), self.PanelFliterCharacterList:GetCurSelectedCharacterId())
        end
    else
        XUiManager.TipText('UiShopFashionFilterSubmitFaultTips')
    end
end

return XUiShopFashionFilter