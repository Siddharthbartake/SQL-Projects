Select * from PortfolioProject..NashvilleHomes
--------------------------------------------------
-- STANDARDIZING DATE FORMAT

ALTER TABLE PortfolioProject..NashvilleHomes
Add SaleDateStandard Date;

UPDATE PortfolioProject..NashvilleHomes
Set SaleDateStandard = CONVERT(DATE, SALEDATE)

Select SaleDateStandard from PortfolioProject..NashvilleHomes

----------------------------------------------------
-- POPULATE MISSING PROPERTY ADDRESS DATA --

Select * from PortfolioProject..NashvilleHomes
-- Where PropertyAddress is null
order by ParcelID

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject..NashvilleHomes a
JOIN PortfolioProject..NashvilleHomes b
on a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject..NashvilleHomes a
JOIN PortfolioProject..NashvilleHomes b
on a.ParcelID = b.ParcelID
AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

----------------------------------------------------
-- SPLITTING LONG ADDRESS INTO COLUMNS
Select PropertyAddress 
From PortfolioProject..NashvilleHomes


SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address
 , SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address
From PortfolioProject..NashvilleHomes


ALTER TABLE PortfolioProject..NashvilleHomes
Add PropertySplitAddress Nvarchar(255);

UPDATE PortfolioProject..NashvilleHomes
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)


ALTER TABLE PortfolioProject..NashvilleHomes
Add PropertySplitCity Nvarchar(255);

UPDATE PortfolioProject..NashvilleHomes
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))



Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From PortfolioProject..NashvilleHomes


ALTER TABLE PortfolioProject..NashvilleHomes
Add OwnerSplitAddress Nvarchar(255);

UPDATE PortfolioProject..NashvilleHomes
Set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)

ALTER TABLE PortfolioProject..NashvilleHomes
Add OwnerSplitCity Nvarchar(255);

UPDATE PortfolioProject..NashvilleHomes
Set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)

ALTER TABLE PortfolioProject..NashvilleHomes
Add OwnerSplitState Nvarchar(255);

UPDATE PortfolioProject..NashvilleHomes
Set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)


----------------------------------------------------
-- CHANGING Y AND N TO YES AND NO IN "SOLD AS VACANT" COLUMN

Select Distinct(SoldAsVacant), COUNT(SoldAsVacant)
From PortfolioProject..NashvilleHomes
Group by SoldAsVacant
Order by 2

Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'YES'
	   When SoldAsVacant = 'N' THEN 'NO'
	   ELSE SoldAsVacant
	   END
From PortfolioProject..NashvilleHomes


Update PortfolioProject..NashvilleHomes
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'YES'
	   When SoldAsVacant = 'N' THEN 'NO'
	   ELSE SoldAsVacant
	   END


----------------------------------------------------

-- REMOVING DUPLICATES

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY	
					UniqueID
					) row_num
From PortfolioProject..NashvilleHomes
)
DELETE
From RowNumCTE
Where row_num > 1


----------------------------------------------------
-- DELETING UNUSED COLUMNS

ALTER TABLE portfolioproject..nashvillehomes
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE portfolioproject..nashvillehomes
DROP COLUMN SaleDate

Select * from PortfolioProject..NashvilleHomes




