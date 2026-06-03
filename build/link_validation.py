#!/usr/bin/env python3
"""
ESP32 RTOS - Linker Script Validator
Arquivo: build/link_validation.py
Descrição: Valida o linker script e detecta problemas de memória
Arquitetura: Xtensa LX6 (ESP32)
"""

import sys
import re
from typing import Dict, List, Tuple

# Regiões de memória do ESP32
MEMORY_REGIONS = {
    'IROM': {'start': 0x40200000, 'size': 0x300000, 'name': 'Instruction ROM'},
    'IRAM': {'start': 0x40080000, 'size': 0x20000, 'name': 'Instruction RAM'},
    'DRAM': {'start': 0x3FFB0000, 'size': 0x50000, 'name': 'Data RAM'},
    'RTC_IRAM': {'start': 0x400C0000, 'size': 0x2000, 'name': 'RTC Instruction RAM'},
    'RTC_DRAM': {'start': 0x50000000, 'size': 0x2000, 'name': 'RTC Data RAM'},
}

# Alocações esperadas
ALLOCATIONS = {
    'KERNEL': {'region': 'IROM', 'estimated_size': 0x2000},
    'DRIVERS': {'region': 'IROM', 'estimated_size': 0x3000},
    'TASKS': {'region': 'DRAM', 'estimated_size': 0x10000},
    'BUFFERS': {'region': 'DRAM', 'estimated_size': 0x2000},
    'STACK': {'region': 'DRAM', 'estimated_size': 0x1000},
    'HEAP': {'region': 'DRAM', 'estimated_size': 0x12000},
}

class MemoryValidator:
    """Validador de layout de memória"""
    
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.allocations = {}
        self.fragmentation = {}
        
    def check_overlap(self) -> bool:
        """Verifica se há sobreposição de regiões"""
        regions = list(MEMORY_REGIONS.values())
        
        for i, region1 in enumerate(regions):
            for region2 in regions[i+1:]:
                start1 = region1['start']
                end1 = region1['start'] + region1['size']
                start2 = region2['start']
                end2 = region2['start'] + region2['size']
                
                # Verificar sobreposição
                if not (end1 <= start2 or end2 <= start1):
                    error = f"Sobreposição: {region1['name']} e {region2['name']}"
                    self.errors.append(error)
                    return False
        
        return True
    
    def check_allocations(self) -> bool:
        """Verifica se as alocações cabem em suas regiões"""
        for name, alloc in ALLOCATIONS.items():
            region_name = alloc['region']
            region = MEMORY_REGIONS[region_name]
            
            total_size = sum(a['estimated_size'] 
                           for a in ALLOCATIONS.values() 
                           if a['region'] == region_name)
            
            if total_size > region['size']:
                error = f"Alocação '{name}' excede {region_name} (total: {hex(total_size)} > {hex(region['size'])})"
                self.errors.append(error)
                return False
        
        return True
    
    def calculate_fragmentation(self) -> Dict[str, float]:
        """Calcula fragmentação de memória por região"""
        fragmentation = {}
        
        for region_name, region in MEMORY_REGIONS.items():
            used_size = sum(a['estimated_size'] 
                          for a in ALLOCATIONS.values() 
                          if a['region'] == region_name)
            
            free_size = region['size'] - used_size
            usage_percent = (used_size / region['size']) * 100
            fragmentation[region_name] = {
                'used': used_size,
                'free': free_size,
                'usage': usage_percent,
            }
        
        self.fragmentation = fragmentation
        return fragmentation
    
    def check_critical_sizes(self) -> bool:
        """Verifica tamanhos críticos"""
        checks = [
            ('STACK', 0x1000, "Stack must be at least 4KB"),
            ('HEAP', 0x2000, "Heap must be at least 8KB"),
            ('KERNEL', 0x1000, "Kernel must be at least 4KB"),
        ]
        
        for name, min_size, msg in checks:
            if ALLOCATIONS[name]['estimated_size'] < min_size:
                self.warnings.append(f"{name}: {msg}")
                return False
        
        return True
    
    def generate_report(self) -> str:
        """Gera relatório de validação"""
        report = []
        report.append("\n" + "="*60)
        report.append("ESP32 RTOS - Linker Script Validation Report")
        report.append("="*60 + "\n")
        
        # Seção de Regiões de Memória
        report.append("MEMORY REGIONS:")
        report.append("-" * 60)
        for name, region in MEMORY_REGIONS.items():
            start = hex(region['start'])
            end = hex(region['start'] + region['size'])
            size = hex(region['size'])
            report.append(f"{name:12} {region['name']:20} [{start} - {end}] ({size})")
        
        # Seção de Alocações
        report.append("\nALLOCATIONS:")
        report.append("-" * 60)
        for name, alloc in ALLOCATIONS.items():
            region = alloc['region']
            size = hex(alloc['estimated_size'])
            report.append(f"{name:12} {region:8} {size}")
        
        # Seção de Fragmentação
        report.append("\nMEMORY USAGE BY REGION:")
        report.append("-" * 60)
        for region_name, frag in self.fragmentation.items():
            used = hex(frag['used'])
            free = hex(frag['free'])
            usage = f"{frag['usage']:.1f}%"
            report.append(f"{region_name:12} Used: {used:8} Free: {free:8} {usage:>6}")
        
        # Seção de Validação
        report.append("\nVALIDATION:")
        report.append("-" * 60)
        
        if self.check_overlap():
            report.append("✓ No memory overlaps detected")
        
        if self.check_allocations():
            report.append("✓ All allocations fit in their regions")
        
        if self.check_critical_sizes():
            report.append("✓ All critical sizes are adequate")
        
        # Erros
        if self.errors:
            report.append("\nERRORS:")
            report.append("-" * 60)
            for error in self.errors:
                report.append(f"✗ {error}")
        
        # Avisos
        if self.warnings:
            report.append("\nWARNINGS:")
            report.append("-" * 60)
            for warning in self.warnings:
                report.append(f"! {warning}")
        
        # Resumo
        status = "PASS" if not self.errors else "FAIL"
        report.append("\n" + "="*60)
        report.append(f"Status: {status}")
        report.append("="*60 + "\n")
        
        return "\n".join(report)
    
    def validate(self) -> bool:
        """Executa validação completa"""
        self.calculate_fragmentation()
        return not self.errors

def main():
    """Função principal"""
    validator = MemoryValidator()
    
    # Executar validações
    validator.check_overlap()
    validator.check_allocations()
    validator.check_critical_sizes()
    
    # Gerar e imprimir relatório
    report = validator.generate_report()
    print(report)
    
    # Retornar código de saída
    return 0 if validator.validate() else 1

if __name__ == "__main__":
    sys.exit(main())
