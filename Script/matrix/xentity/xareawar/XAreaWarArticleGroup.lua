
---@class XAreaWarArticle 文章数据
---@field _Id number
---@field _PublicTimeStamp number 解锁时间戳
---@field _LikeCount number 点赞数
local XAreaWarArticle = XClass(nil, "XAreaWarArticle")

-- 保留两位小数
local Decimal = 100

function XAreaWarArticle:Ctor(id)
    self._Id = id
end

function XAreaWarArticle:Update(timeStamp, likeCount)
    self._PublicTimeStamp = timeStamp
    self._LikeCount = likeCount
end

function XAreaWarArticle:GetTimeString(timeFormat)
    timeFormat = timeFormat or "yyyy-MM-dd"
    return XTime.TimestampToGameDateTimeString(self._PublicTimeStamp, timeFormat)
end

function XAreaWarArticle:GetLikeCount()
    return self._LikeCount
end

function XAreaWarArticle:Like()
    self._LikeCount = self._LikeCount + 1
end

function XAreaWarArticle:GetLikeCountString()
    local boundary = XAreaWarConfigs.GetArticleLikeBoundary()
    if self._LikeCount <= boundary then
        return tostring(self._LikeCount)
    end
    
    local count = math.floor((self._LikeCount / boundary) * Decimal) / Decimal
    return count .. XAreaWarConfigs.GetArticleLikeBoundaryUnit()
end

function XAreaWarArticle:GetId()
    return self._Id
end

function XAreaWarArticle:GetPriority()
    return XAreaWarConfigs.GetArticlePriority(self._Id)
end


---@class XAreaWarArticleGroup 文章组数据
---@field _GroupId number
---@field _UnlockArticleMap table<number, XAreaWarArticle>
---@field _IsUnlock boolean
local XAreaWarArticleGroup = XClass(nil, "XAreaWarArticleGroup")

function XAreaWarArticleGroup:Ctor(groupId)
    self._GroupId = groupId
    self._UnlockArticleMap = {}
    self._IsUnlock = false
end

function XAreaWarArticleGroup:Update(isUnlock, unlockArticles)
    self._IsUnlock = isUnlock ~= 0
    unlockArticles = unlockArticles or {}
    for _, article in pairs(unlockArticles) do
        local data = self._UnlockArticleMap[article.ArticleId]
        if not data then
            data = XAreaWarArticle.New(article.ArticleId)
            self._UnlockArticleMap[article.ArticleId] = data
        end
        data:Update(article.PublicTimeStamp, article.LikeCount)
    end
end

function XAreaWarArticleGroup:CheckGroupIsUnlock()
    return self._IsUnlock
end

--- 获取文章数据，已解锁才有
---@param articleId number 文章Id
---@return XAreaWarArticle
--------------------------
function XAreaWarArticleGroup:GetArticleData(articleId)
    local data = self._UnlockArticleMap[articleId]
    if not data then
        XLog.Error("获取了未解锁的文章数据, 请检查调用逻辑!! articleId = " .. tostring(articleId))
        return
    end
    return data
end

function XAreaWarArticleGroup:IsArticleEmpty()
    return XTool.IsTableEmpty(self._UnlockArticleMap)
end

function XAreaWarArticleGroup:GetUnlockArticleList()
    local list = {}
    for _, article in pairs(self._UnlockArticleMap) do
        table.insert(list, article)
    end
    
    table.sort(list, function(a, b) 
        local pA = a:GetPriority()
        local pB = b:GetPriority()
        if pA ~= pB then
            return pA < pB
        end
        
        return a:GetId() < b:GetId()
    end)
    
    return list
end


return XAreaWarArticleGroup