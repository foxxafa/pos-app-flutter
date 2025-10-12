<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "goods_receipts".
 *
 * @property int $goods_receipt_id
 * @property string|null $operation_unique_id
 * @property int $warehouse_id
 * @property int|null $siparis_id İlişkili satınalma sipariş fişi IDsi
 * @property string|null $invoice_number
 * @property string|null $delivery_note_number
 * @property int|null $employee_id İşlemi yapan çalışan IDsi
 * @property string $receipt_date Mal kabul tarihi
 * @property string $created_at
 * @property string|null $updated_at
 * @property string|null $warehouse_code
 * @property string|null $sip_fisno
 *
 * @property Employees $employee
 * @property GoodsReceiptItems[] $goodsReceiptItems
 * @property InventoryStock[] $inventoryStocks
 * @property Warehouses $warehouse
 */
class GoodsReceipts extends \yii\db\ActiveRecord
{


    /**
     * {@inheritdoc}
     */
    public static function tableName()
    {
        return 'goods_receipts';
    }

    /**
     * {@inheritdoc}
     */
    public function rules()
    {
        return [
            [['siparis_id', 'invoice_number', 'delivery_note_number', 'employee_id', 'warehouse_code', 'sip_fisno', 'operation_unique_id'], 'default', 'value' => null],
            [['warehouse_id', 'receipt_date'], 'required'],
            [['warehouse_id', 'siparis_id', 'employee_id'], 'integer'],
            [['receipt_date', 'created_at', 'updated_at'], 'safe'],
            [['invoice_number', 'delivery_note_number', 'operation_unique_id'], 'string', 'max' => 255],
            [['warehouse_code', 'sip_fisno'], 'string', 'max' => 45],
            [['employee_id'], 'exist', 'skipOnError' => true, 'targetClass' => Employees::class, 'targetAttribute' => ['employee_id' => 'id']],
            [['warehouse_id'], 'exist', 'skipOnError' => true, 'targetClass' => Warehouses::class, 'targetAttribute' => ['warehouse_id' => 'id']],
        ];
    }

    /**
     * {@inheritdoc}
     */
    public function attributeLabels()
    {
        return [
            'goods_receipt_id' => 'Goods Receipt ID',
            'operation_unique_id' => 'Operation Unique ID',
            'warehouse_id' => 'Warehouse ID',
            'siparis_id' => 'Siparis ID',
            'invoice_number' => 'Invoice Number',
            'delivery_note_number' => 'Delivery Note Number',
            'employee_id' => 'Employee ID',
            'receipt_date' => 'Receipt Date',
            'created_at' => 'Created At',
            'updated_at' => 'Updated At',
            'warehouse_code' => 'Warehouse Code',
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
     * Gets query for [[GoodsReceiptItems]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getGoodsReceiptItems()
    {
        return $this->hasMany(GoodsReceiptItems::class, ['receipt_id' => 'goods_receipt_id']);
    }

    /**
     * Gets query for [[InventoryStocks]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getInventoryStocks()
    {
        return $this->hasMany(InventoryStock::class, ['goods_receipt_id' => 'goods_receipt_id']);
    }
    public function getSiparis()
    {
        // return $this->hasOne(Siparisler::class, ['fisno' => 'sip_fisno']);
        return $this->hasOne(Siparisler::class, ['id' => 'siparis_id']);
    }


    /**
     * Gets query for [[Warehouse]].
     *
     * @return \yii\db\ActiveQuery
     */
    public function getWarehouse()
    {
        return $this->hasOne(Warehouses::class, ['warehouse_code' => 'warehouse_code']);
    }

}
