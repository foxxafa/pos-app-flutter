<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "wms_count_items".
 *
 * @property int $id
 * @property string $operation_unique_id
 * @property string $item_uuid
 * @property string|null $birim_key Birim key (ürün modunda)
 * @property string|null $pallet_barcode NULL=ürün sayımı, DOLU=palet sayımı
 * @property float $quantity_counted
 * @property string|null $barcode
 * @property string|null $StokKodu
 * @property string|null $shelf_code
 * @property string|null $expiry_date Son kullanma tarihi (ürün modunda)
 * @property string $created_at
 * @property string|null $updated_at
 */
class WmsCountItems extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'wms_count_items';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['birim_key', 'pallet_barcode', 'barcode', 'StokKodu', 'shelf_code', 'expiry_date', 'updated_at'], 'default', 'value' => null],
            [['operation_unique_id', 'item_uuid', 'quantity_counted'], 'required'],
            [['quantity_counted'], 'number'],
            [['created_at', 'updated_at'], 'safe'],
            [['operation_unique_id', 'item_uuid', 'birim_key', 'pallet_barcode', 'barcode', 'StokKodu', 'shelf_code'], 'string', 'max' => 100],
            [['expiry_date'], 'string', 'max' => 20],
            [['item_uuid'], 'unique'],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'operation_unique_id' => 'Operation Unique ID',
            'item_uuid' => 'Item Uuid',
            'birim_key' => 'Birim Key',
            'pallet_barcode' => 'Pallet Barcode',
            'quantity_counted' => 'Quantity Counted',
            'barcode' => 'Barcode',
            'StokKodu' => 'Stok Kodu',
            'shelf_code' => 'Shelf Code',
            'expiry_date' => 'Expiry Date',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
        ];
    }

}
