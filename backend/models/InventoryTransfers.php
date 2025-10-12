<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "inventory_transfers".
 *
 * @property int $id
 * @property string|null $urun_key
 * @property int|null $from_location_id
 * @property int|null $to_location_id
 * @property float $quantity
 * @property string|null $from_pallet_barcode
 * @property string|null $pallet_barcode
 * @property int|null $employee_id
 * @property string $transfer_date
 * @property int|null $siparis_id
 * @property int|null $goods_receipt_id
 * @property string|null $delivery_note_number
 * @property string $created_at
 * @property string|null $updated_at
 * @property string|null $StokKodu
 * @property string|null $from_shelf
 * @property string|null $to_shelf
 * @property string|null $sip_fisno
 *
 * @property Employees $employee
 * @property Shelfs $fromShelf
 * @property Shelfs $toShelf
 * @property Urunler $urun
 */
class InventoryTransfers extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'inventory_transfers';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['urun_key', 'from_location_id', 'to_location_id', 'from_pallet_barcode', 'pallet_barcode', 'employee_id', 'siparis_id', 'goods_receipt_id', 'delivery_note_number', 'StokKodu', 'from_shelf', 'to_shelf', 'sip_fisno'], 'default', 'value' => null],
            [['from_location_id', 'to_location_id', 'employee_id', 'siparis_id', 'goods_receipt_id'], 'integer'],
            [['quantity', 'transfer_date'], 'required'],
            [['quantity'], 'number'],
            [['transfer_date', 'created_at', 'updated_at'], 'safe'],
            [['urun_key'], 'string', 'max' => 10],
            [['from_pallet_barcode', 'pallet_barcode', 'StokKodu', 'sip_fisno'], 'string', 'max' => 50],
            [['from_shelf', 'to_shelf'], 'string', 'max' => 20],
            [['delivery_note_number'], 'string', 'max' => 255],
            [['employee_id'], 'exist', 'skipOnError' => true, 'targetClass' => Employees::class, 'targetAttribute' => ['employee_id' => 'id']],
            [['from_location_id'], 'exist', 'skipOnError' => true, 'targetClass' => Shelfs::class, 'targetAttribute' => ['from_location_id' => 'id']],
            [['to_location_id'], 'exist', 'skipOnError' => true, 'targetClass' => Shelfs::class, 'targetAttribute' => ['to_location_id' => 'id']],
            [['urun_key'], 'exist', 'skipOnError' => true, 'targetClass' => Urunler::class, 'targetAttribute' => ['urun_key' => '_key']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'urun_key' => 'Urun Key',
            'from_location_id' => 'From Location ID',
            'to_location_id' => 'To Location ID',
            'quantity' => 'Quantity',
            'from_pallet_barcode' => 'From Pallet Barcode',
            'pallet_barcode' => 'Pallet Barcode',
            'employee_id' => 'Employee ID',
            'transfer_date' => 'Transfer Date',
            'siparis_id' => 'Siparis ID',
            'goods_receipt_id' => 'Goods Receipt ID',
            'delivery_note_number' => 'Delivery Note Number',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
            'StokKodu' => 'Stok Kodu',
            'from_shelf' => 'Kaynak Raf',
            'to_shelf' => 'Hedef Raf',
            'sip_fisno' => 'Sipariş Fiş No',
        ];
    }

    /**
     * Gets query for [[Employee]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getEmployee()
    {
        return $this->hasOne(Employees::class, ['id' => 'employee_id']);
    }

    /**
     * Gets query for [[FromShelf]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getFromShelf()
    {
        return $this->hasOne(Shelfs::class, ['code' => 'from_shelf']);
    }

    /**
     * Gets query for [[ToShelf]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getToShelf()
    {
        return $this->hasOne(Shelfs::class, ['code' => 'to_shelf']);
    }

    /**
     * Gets query for [[Urun]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getUrun()
    {
        return $this->hasOne(Urunler::class, ['StokKodu' => 'StokKodu']);
    }

}
