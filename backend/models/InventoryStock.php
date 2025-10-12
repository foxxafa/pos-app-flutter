<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "inventory_stock".
 *
 * @property int $id
 * @property string|null $stock_uuid
 * @property string|null $warehouse_code
 * @property string|null $urun_key
 * @property string|null $birim_key
 * @property int|null $location_id
 * @property int|null $siparis_id
 * @property int|null $goods_receipt_id
 * @property float $quantity
 * @property string|null $pallet_barcode
 * @property string $stock_status
 * @property string $updated_at
 * @property string|null $expiry_date
 * @property string|null $created_at
 * @property string|null $StokKodu
 * @property string|null $shelf_code
 * @property string|null $sip_fisno
 *
 * @property GoodsReceipts $goodsReceipt
 * @property Urunler $urun
 * @property Shelfs $shelf
 */
class InventoryStock extends \yii\db\ActiveRecord
{

    /**
     * ENUM field values
     */
    const STOCK_STATUS_RECEIVING = 'receiving';
    const STOCK_STATUS_AVAILABLE = 'available';

    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'inventory_stock';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['urun_key', 'location_id', 'siparis_id', 'goods_receipt_id', 'pallet_barcode', 'expiry_date', 'StokKodu', 'shelf_code', 'sip_fisno', 'stock_uuid', 'warehouse_code', 'birim_key'], 'default', 'value' => null],
            [['stock_status'], 'default', 'value' => 'available'],
            [['location_id', 'siparis_id', 'goods_receipt_id'], 'integer'],
            [['quantity'], 'required'],
            [['quantity'], 'number'],
            [['stock_status'], 'string'],
            [['updated_at', 'expiry_date', 'created_at'], 'safe'],
            [['stock_uuid'], 'string', 'max' => 36],
            [['warehouse_code'], 'string', 'max' => 255],
            [['birim_key'], 'string', 'max' => 45],
            [['urun_key'], 'string', 'max' => 10],
            [['pallet_barcode'], 'string', 'max' => 255],
            [['StokKodu', 'sip_fisno'], 'string', 'max' => 50],
            [['shelf_code'], 'string', 'max' => 20],
            ['stock_status', 'in', 'range' => array_keys(self::optsStockStatus())],
            [['location_id', 'pallet_barcode', 'stock_status', 'siparis_id', 'expiry_date', 'goods_receipt_id'], 'unique', 'targetAttribute' => ['location_id', 'pallet_barcode', 'stock_status', 'siparis_id', 'expiry_date', 'goods_receipt_id']],
            [['location_id'], 'exist', 'skipOnError' => true, 'targetClass' => Shelfs::class, 'targetAttribute' => ['location_id' => 'id']],
            [['goods_receipt_id'], 'exist', 'skipOnError' => true, 'targetClass' => GoodsReceipts::class, 'targetAttribute' => ['goods_receipt_id' => 'goods_receipt_id']],
            [['StokKodu'], 'exist', 'skipOnError' => true, 'targetClass' => Urunler::class, 'targetAttribute' => ['StokKodu' => 'StokKodu']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'stock_uuid' => 'Stock Uuid',
            'warehouse_code' => 'Warehouse Code',
            'urun_key' => 'Urun Key',
            'birim_key' => 'Birim Key',
            'location_id' => 'Location ID',
            'siparis_id' => 'Siparis ID',
            'goods_receipt_id' => 'Goods Receipt ID',
            'quantity' => 'Quantity',
            'pallet_barcode' => 'Pallet Barcode',
            'stock_status' => 'Stock Status',
            'updated_at' => 'Updated At',
            'expiry_date' => 'Expiry Date',
            'created_at' => 'Created At',
            'StokKodu' => 'Stok Kodu',
            'shelf_code' => 'Raf Kodu',
            'sip_fisno' => 'Sipariş Fiş No',
        ];
    }

    /**
     * Gets query for [[GoodsReceipt]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getGoodsReceipt()
    {
        return $this->hasOne(GoodsReceipts::class, ['goods_receipt_id' => 'goods_receipt_id']);
    }

    /**
     * Gets query for [[Shelf]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getShelf()
    {
        return $this->hasOne(Shelfs::class, ['code' => 'shelf_code']);
    }

    /**
     * Gets query for [[Urun]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getUrun()
    {
        return $this->hasOne(Urunler::class, ['_key' => 'urun_key']);
    }


    /**
     * column stock_status ENUM value labels
     * @return string[]
     */
    public static function optsStockStatus()
    {
        return [
            self::STOCK_STATUS_RECEIVING => 'receiving',
            self::STOCK_STATUS_AVAILABLE => 'available',
        ];
    }

    /**
     * @return string
     */
    public function displayStockStatus()
    {
        return self::optsStockStatus()[$this->stock_status];
    }

    /**
     * @return bool
     */
    public function isStockStatusReceiving()
    {
        return $this->stock_status === self::STOCK_STATUS_RECEIVING;
    }

    public function setStockStatusToReceiving()
    {
        $this->stock_status = self::STOCK_STATUS_RECEIVING;
    }

    /**
     * @return bool
     */
    public function isStockStatusAvailable()
    {
        return $this->stock_status === self::STOCK_STATUS_AVAILABLE;
    }

    public function setStockStatusToAvailable()
    {
        $this->stock_status = self::STOCK_STATUS_AVAILABLE;
    }
}
